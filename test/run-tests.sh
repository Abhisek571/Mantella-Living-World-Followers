#!/usr/bin/env bash
# Drives the Followers scenarios over DevBench (game running, a save with the NPC in the NFF party), then prints
# PASS/FAIL per check. The sit step needs someone at the game: look at a chair when the HUD says so.
# usage: bash run-tests.sh [npc form] [other party member]     e.g. 0xFE1DD821 0xFE26080E (Mjoll, nyri in the test save)
set -u
MO2=${MO2:?set MO2 to your Mod Organizer 2 instance folder}
NPC=${1:-0xFE1DD821}
NPC2=${2:-0xFE26080E}                     # the other party member (nyri in the test save)
V="{\"form\":\"$NPC\"}"; P='{"form":"0x14"}'; Q='{"form":"MLWF_Quest"}'
LYDIA='{"form":"0xA2C94"}'                     # HousecarlWhiterunRef: a friendly NPC who is not an enemy
WOLF='{"form":"0x23ABE"}'; TORCH='{"form":"0x1D4EC"}'; CUIRASS='{"form":"0x13952"}'; SWORD='{"form":"0x12EB7"}'
ORDER_ATTACK=7; ORDER_BEHIND=8; ORDER_DISTANCE=9; ORDER_STYLE=10; ORDER_ROLE=11; ORDER_SIT=12; ORDER_TORCH=13
pass=0; fail=0

# call <script> <function> [args json] [self json]: prints the return value as JSON ("ERROR ..." on failure)
call() { bash "$MO2/tools/devbench-cli.sh" call "$@" 2>&1 | py -3 -I -c "import json,sys
try:
    d=json.load(sys.stdin); print(json.dumps(d.get('returned')) if d.get('called') else 'ERROR '+str(d))
except Exception: print('ERROR no reply')"; }
m() { call MLWF_Main "$1" "${2:-[]}" "$Q"; }       # member function of the Followers quest
order() { m Order "[$1,$V,\"${2:-}\"]" >/dev/null; sleep "${3:-2}"; }
state() { m TestState "[$V]"; }
event() { m TestTakeEvent; }
con() { bash "$MO2/tools/devbench-cli.sh" exec "$1" >/dev/null 2>&1; }
note() { bash "$MO2/tools/devbench-cli.sh" notify "$1" >/dev/null 2>&1; echo "== $1"; }
# check <label> <extended regex> <text>
check() { if printf '%s' "$3" | grep -qiE -- "$2"; then pass=$((pass+1)); echo "   PASS $1"; else fail=$((fail+1)); echo "   FAIL $1: $3"; fi; }
nocheck() { if printf '%s' "$3" | grep -qiE -- "$2"; then fail=$((fail+1)); echo "   FAIL $1: $3"; else pass=$((pass+1)); echo "   PASS $1"; fi; }
distance() { call ObjectReference GetDistance "[$P]" "$V"; }

con "set GameHour to 12"
m TestTakeEvent >/dev/null

note "0/12 setup: the NPC is in the NFF party"
s=$(state); check "in party" 'party=TRUE' "$s"
if ! printf '%s' "$s" | grep -qi 'party=TRUE'; then order 0 "" 10; check "joined" 'party=TRUE' "$(state)"; fi
order 3 "" 2   # follow, in case she waits

note "1/12 follow distance: near=rank 1, far=rank 2, normal=rank 0"
order $ORDER_DISTANCE near; check "near" 'range=1 ' "$(state)"
order $ORDER_DISTANCE far; check "far" 'range=2 ' "$(state)"
order $ORDER_DISTANCE normal; check "normal" 'range=0 ' "$(state)"

note "2/12 combat style: ranged=3 (Archer), magic=6 (Wizard), melee=0 (Mercenary)"
order $ORDER_STYLE ranged; s=$(state); check "ranged" 'style=3 ' "$s"; echo "   event: $(event)"
order $ORDER_STYLE magic; check "magic" 'style=6 ' "$(state)"
order $ORDER_STYLE melee; check "melee" 'style=0 ' "$(state)"

note "3/12 role: tank=2, healer=1 (or a refusal line), none=0"
order $ORDER_ROLE tank; check "tank" 'role=2 ' "$(state)"
order $ORDER_ROLE healer; s=$(state); e=$(event)
if printf '%s' "$e" | grep -qi 'not strong enough'; then check "healer refused with a line" 'healer' "$e"; else check "healer" 'role=1 ' "$s"; fi
order $ORDER_ROLE none; check "none" 'role=0 ' "$(state)"

note "4/12 torch: off takes her torches, on gives one back (from the player if NFF stored none)"
call ObjectReference AddItem "[$TORCH,1,true]" "$P" >/dev/null
order $ORDER_TORCH off; check "torch off" 'torches=0 ' "$(state)"
order $ORDER_TORCH on; check "torch on" 'torches=[1-9]' "$(state)"

note "5/12 stay behind: she ends up right behind the player"
order $ORDER_BEHIND "" 2; d=$(distance); check "behind (distance $d)" '^"?([0-9]|[0-9][0-9]|[12][0-9][0-9])(\.|"|$)' "$d"   # placed 64 behind; she may walk a little after

note "6/12 relax: NFF relax mode on"
m Relax >/dev/null; sleep 1; check "relax on" 'relax=([1-9])' "$(state)"; echo "   event: $(event)"

note "7/12 loot on, then off"
m Loot '[true]' >/dev/null; sleep 4; check "loot on" 'looting=TRUE' "$(state)"
m Loot '[false]' >/dev/null; sleep 4; check "loot off" 'looting=FALSE' "$(state)"
event >/dev/null

note "8/12 attack a friendly NPC (Lydia): refused with an event line, no fight"
call ObjectReference MoveTo "[$P,300.0,0.0,0.0,true]" "$LYDIA" >/dev/null; sleep 3
order $ORDER_ATTACK Lydia 3; sleep 3; e=$(event); s=$(state)   # the refusal line comes after the target lookup
check "refusal line" 'refuses to attack Lydia' "$e"; check "no fight" 'combat=FALSE' "$s"
call ObjectReference MoveToMyEditorLocation '[]' "$LYDIA" >/dev/null

note "9/12 attack an enemy (spawned wolf): she fights it"
wolf=$(call ObjectReference PlaceAtMe "[$WOLF,1,false,false]" "$P")
wolf_form="{\"form\":\"$(printf '%s' "$wolf" | grep -oE '0x[0-9A-Fa-f]+' | head -1)\"}"
if printf '%s' "$wolf" | grep -q '^ERROR\|^null'; then fail=$((fail+1)); echo "   FAIL no wolf spawned: $wolf"
else
  call Actor SetActorValue '["Health",5000.0]' "$wolf_form" >/dev/null   # Riverwood's guards kill a plain wolf within seconds
  sleep 1
  order $ORDER_ATTACK Wolf 3; s=$(state); for k in 1 2 3 4; do printf '%s' "$s" | grep -q 'combat=TRUE' && break; sleep 2; s=$(state); done
  check "fighting" 'combat=TRUE' "$s"; nocheck "not refused" 'refuses' "$(event)"
  call Actor Kill '[null]' "$wolf" >/dev/null; sleep 3
fi

note "10/12 sit: LOOK AT A FREE CHAIR NOW (10 s)"
sleep 10; order $ORDER_SIT "" 6; s=$(state); e=$(event)
check "sitting (or told there is no seat)" 'sit=[1-4]|no seat|taken' "$s $e"
order 3 "" 3   # follow again

note "11/12 gather: party near or in view gathers without a warp; far and out of view catches up"
m Gather >/dev/null; sleep 2; check "near: no warp" 'gathers around' "$(event)"
call ObjectReference MoveTo "[$LYDIA,0.0,0.0,0.0,true]" "$V" >/dev/null   # Lydia's spot in Dragonsreach
[ -n "${NPC2:-}" ] && call ObjectReference MoveTo "[$LYDIA,60.0,0.0,0.0,true]" "{\"form\":\"$NPC2\"}" >/dev/null   # the warp needs everyone away
sleep 3
check "moved away (distance)" '^"?[0-9]{4,}|e\+' "$(distance)"
m Gather >/dev/null; sleep 5; check "far: catches up" 'catches up' "$(event)"; echo "   distance now: $(distance)"

note "12/12 clothes: own outfit = no line, given cuirass = one line naming it, given sword only = no line"
base=$(m CheckClothes "[$V]"); event >/dev/null
check "own outfit, no line (if this fails she already wears given clothes)" '^""$' "$base"
oldBody=$(call Actor GetWornForm '[4]' "$V")
call ObjectReference AddItem "[$CUIRASS,1,true]" "$P" >/dev/null   # the player hands it over, as a gift or trade would
call ObjectReference RemoveItem "[$CUIRASS,1,true,$V]" "$P" >/dev/null; sleep 1
call Actor EquipItem "[$CUIRASS,false,true]" "$V" >/dev/null; sleep 2
l=$(m CheckClothes "[$V]"); check "given cuirass named" 'wears Steel Armor.*gave (her|him)' "$l"; check "event sent" 'Steel Armor' "$(event)"
call Actor UnequipItem "[$CUIRASS,false,true]" "$V" >/dev/null
call ObjectReference RemoveItem "[$CUIRASS,1,true,null]" "$V" >/dev/null
[ "$oldBody" != "null" ] && call Actor EquipItem "[$oldBody,false,true]" "$V" >/dev/null
sleep 2
call ObjectReference AddItem "[$SWORD,1,true]" "$V" >/dev/null
call Actor EquipItem "[$SWORD,false,true]" "$V" >/dev/null; sleep 2
l=$(m CheckClothes "[$V]"); nocheck "sword not counted" 'Iron Sword' "$l"   # equipping a weapon makes the engine re-equip her best armor, so only the sword is checked
call ObjectReference RemoveItem "[$SWORD,1,true,null]" "$V" >/dev/null
event >/dev/null

note "tests finished: $pass passed, $fail failed"
echo "NFF combat style, role, range and relax were changed on this save; reload it or reset them in NFF's menu."
[ "$fail" -eq 0 ]
