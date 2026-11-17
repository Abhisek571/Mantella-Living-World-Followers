"""Offline checks for the two order actions (FollowerOrder, PartyOrder), no game needed:
  - both action files are well formed, gated to NFF party members, and list exactly the orders the script knows;
  - every order is passed on to the handler (or order code) of the separate action it replaced, with the right choice;
  - an unknown order, and the legacy event (no arguments), tell the talk that nothing happened;
  - the separate actions of the previous version stay registered for one version, and nothing else ships for them.
usage: py -3 test/check_orders.py
"""
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ACTIONS = os.path.join(ROOT, 'SKSE', 'Plugins', 'MantellaSoftware', 'data', 'actions')
SRC = open(os.path.join(ROOT, 'Source', 'Scripts', 'MLWF_Main.psc'), encoding='utf-8').read()
fails = 0


def check(name, ok, detail=''):
    global fails
    print(('PASS ' if ok else 'FAIL ') + name + ('' if ok else f': {detail}'))
    fails += not ok


def event(name):
    m = re.search(r'^Event ' + name + r'\(.*?^EndEvent', SRC, re.M | re.S)
    return m.group(0) if m else ''


def branch(body, test):
    """The lines run when the If/ElseIf with this test holds (up to the next ElseIf/Else/EndIf at that level)."""
    m = re.search(r'(?:If|ElseIf) ' + re.escape(test) + r'\n(.*?)\n\t(?:ElseIf|Else|EndIf)', body, re.S)
    return m.group(1) if m else ''


files = {f: json.load(open(os.path.join(ACTIONS, f), encoding='utf-8')) for f in os.listdir(ACTIONS) if f.endswith('.json')}
check('action files: JoinParty, FollowerOrder, PartyOrder', sorted(d['name'] for d in files.values()) == ['FollowerOrder', 'JoinParty', 'PartyOrder'],
      sorted(d['name'] for d in files.values()))
order = files.get('mantella_mlw_order.json', {})
party = files.get('mantella_mlw_party_order.json', {})
for d in (order, party):
    check(f"{d.get('name')}: identifier = file name, key = name", d.get('identifier', '') + '.json' in files and d.get('key') == d.get('name'))
    check(f"{d.get('name')}: only for NFF party members", d.get('lw_gate') == 'nff=1', d.get('lw_gate'))
    check(f"{d.get('name')}: order is required", 'order' in d.get('required', []))
check('FollowerOrder names the followers (source, conversation scope)', order['parameters']['source'].get('scope') == 'conversation' and 'source' in order['required'])

# FollowerOrder: order -> what it must call
FOLLOWER = {
    'follow': 'OnFollowAdvanced(', 'wait': 'OnWaitAdvanced(', 'stay_behind': 'OnBehindAdvanced(', 'sit': 'OnSitAdvanced(',
    'leave': 'OnLeaveAdvanced(', 'wear': 'OnWearAdvanced(', 'fight': 'OnAggressiveAdvanced(', 'passive': 'OnPassiveAdvanced(',
    'attack': 'OnAttackAdvanced(',
}
PREFIXED = {'distance_': ('ORDER_DISTANCE', 9, ['near', 'normal', 'far']), 'style_': ('ORDER_STYLE', 6, ['melee', 'ranged', 'magic']),
            'role_': ('ORDER_ROLE', 5, ['tank', 'healer', 'none']), 'torch_': ('ORDER_TORCH', 6, ['on', 'off'])}
enum = order['parameters']['order']['enum']
want = list(FOLLOWER) + [p + c for p, (_, _, cs) in PREFIXED.items() for c in cs]
check('FollowerOrder: the order list is every order the script knows', sorted(enum) == sorted(want), sorted(set(enum) ^ set(want)))
body = event('OnOrderAdvanced')
check('FollowerOrder: reads the order', 'SKSE_HTTP.getString(aiArguments, "order", "")' in body)
for name, call in FOLLOWER.items():
    run = branch(body, f'order == "{name}"')
    check(f'FollowerOrder {name}: runs {call[:-1]}', call + 'akSpeaker, akConversation, aiArguments)' in run, run)
    check(f'FollowerOrder {name}: that handler exists', bool(event(call[:-1])))
for prefix, (code, cut, choices) in PREFIXED.items():
    run = branch(body, f'StringUtil.Find(order, "{prefix}") == 0')
    check(f'FollowerOrder {prefix}*: {code} with the choice after the prefix', f'Orders({code}, ResolveSources(akSpeaker, akConversation, aiArguments), StringUtil.Substring(order, {cut}))' in run
          and len(prefix) == cut, run)
    for c in choices:
        check(f'FollowerOrder {prefix}{c}: the order function knows "{c}"', f'"{c}"' in SRC)
check('FollowerOrder: an unknown order tells the talk nothing happened', 'Tell("", "Nothing happened: the game was not told which order (" + order + ").")' in body)
check('FollowerOrder legacy (no arguments): tells the talk nothing happened', 'Nothing happened' in event('OnOrderLegacy'))

# PartyOrder
PARTY = {'follow': 'OnFollowAllAdvanced(', 'wait': 'OnWaitAllAdvanced(', 'gather': 'OnGatherAdvanced(', 'relax': 'OnRelaxAdvanced('}
penum = party['parameters']['order']['enum']
check('PartyOrder: the order list', sorted(penum) == sorted(list(PARTY) + ['loot_on', 'loot_off']), penum)
pbody = event('OnPartyOrderAdvanced')
for name, call in PARTY.items():
    run = branch(pbody, f'order == "{name}"')
    check(f'PartyOrder {name}: runs {call[:-1]} (which checks the speaker is in the party)', call + 'akSpeaker, akConversation, aiArguments)' in run
          and 'SpeakerInParty(akSpeaker)' in event(call[:-1]), run)
loot = branch(pbody, 'order == "loot_on" || order == "loot_off"')
check('PartyOrder loot_on / loot_off: only from a party member, on or off', 'If SpeakerInParty(akSpeaker)' in loot and 'Loot(order == "loot_on")' in loot, loot)
check('PartyOrder: an unknown order tells the talk nothing happened', 'which party order (" + order + ")' in pbody)
check('PartyOrder legacy (no arguments): tells the talk nothing happened', 'Nothing happened' in event('OnPartyOrderLegacy'))

# Registration: the two new actions, plus the separate ones of the previous version for one version
registered = {(p, i): h for p, i, h in re.findall(r'RegisterForModEvent\((ADVANCED|PREFIX) \+ "(mantella_mlw_\w+)", "(\w+)"\)', SRC)}
for ident, adv, leg in (('mantella_mlw_order', 'OnOrderAdvanced', 'OnOrderLegacy'), ('mantella_mlw_party_order', 'OnPartyOrderAdvanced', 'OnPartyOrderLegacy')):
    check(f'{ident}: both events registered', registered.get(('ADVANCED', ident)) == adv and registered.get(('PREFIX', ident)) == leg)
OLD = ['leave', 'wait', 'follow', 'passive', 'aggressive', 'wear', 'wait_all', 'follow_all', 'attack_target', 'stay_behind', 'follow_distance',
       'combat_style', 'role', 'sit_there', 'torch', 'relax_here', 'loot', 'gather_party']
missing = [o for o in OLD if ('ADVANCED', 'mantella_mlw_' + o) not in registered]
check('the 18 separate actions of the previous version stay registered (a running talk)', not missing, missing)
check('no action file left for them', not any(f'mantella_mlw_{o}.json' in files for o in OLD))

# Live test 5: style_melee and distance_near gave no event line, so neither the NPC nor the player knew they applied.
# Every order function tells its result (an event line, and a HUD line where something changed) and every refusal.
def function(name):
    m = re.search(r'^Function ' + name + r'\(.*?^EndFunction', SRC, re.M | re.S)
    return m.group(0) if m else ''


ORDER_FUNCS = ['Order', 'PartyOrder', 'Join', 'Behave', 'AttackFound', 'FollowDistance', 'CombatStyle', 'Role', 'Sit', 'Torch',
               'Relax', 'Loot', 'Gather']
for fn in ORDER_FUNCS:
    code = function(fn)
    check(f'{fn}: exists', bool(code))
    check(f'{fn}: no HUD line without an event line (Tell, not Debug.Notification)', 'Debug.Notification(' not in code, fn)
    lines = code.splitlines()
    silent = []
    for i, line in enumerate(lines):
        if line.strip() == 'Return' and not any('Tell(' in l for l in lines[max(0, i - 6):i]):
            silent.append(i)
    allowed = 1 if fn == 'Order' else 0  # Order: no actor at all (nobody to tell about)
    check(f'{fn}: every early return tells why', len(silent) <= allowed, [lines[i - 1].strip() for i in silent])
    tells = re.findall(r'Tell\(("[^"]*"|[^,]+?),\s*(.+?)\)\s*$', code, re.M)
    check(f'{fn}: every told-back line has an event part', all(not ev.startswith('""') for _, ev in tells), [ev for _, ev in tells if ev.startswith('""')])
# each order kind of FollowerOrder and PartyOrder reaches a function that tells its result on success
SUCCESS = {'ORDER_WAIT': 'waits here until asked to follow', 'ORDER_FOLLOW': 'follows the player.', 'ORDER_LEAVE': "has left the player's party",
           'ORDER_BEHIND': 'stays right behind the player'}
order_code = function('Order')
for code_name, text in SUCCESS.items():
    check(f'{code_name}: told back', text in branch(order_code, f'aiOrder == {code_name}') or text in order_code, code_name)
for fn, text in (('FollowDistance', '" now follows the player at " + asDistance + " distance."'), ('CombatStyle', '" now fights in " + asStyle + " style."'),
                 ('Role', '" is now the party\'s " + asRole + "."'), ('Torch', '" carries a torch in the dark."'), ('Behave', '" now stays out of fights."'),
                 ('Behave', '" now fights freely and helps the party."'), ('AttackFound', '" attacks " + targetName + "."'), ('Join', '" has joined the player\'s party."'),
                 ('PartyOrder', '"The followers near the player wait here."'), ('PartyOrder', '"The followers near the player follow them."'),
                 ('Gather', '"The followers near the player gather around them."'), ('Relax', '"The party relaxes nearby while the player stays put."'),
                 ('Loot', '"The party loots bodies and containers nearby."'), ('Loot', '"The party stops looting."')):
    check(f'{fn}: success told back as an event line ({text[:40]})', text in function(fn), fn)
for fn, text in (('FollowDistance', 'which follow distance'), ('CombatStyle', 'which fighting style'), ('Role', 'which role'), ('Torch', 'should carry a torch')):
    check(f'{fn}: an unknown choice is refused with a line', text in function(fn))


# The script lock: a stale lock (older than LOCK_TIMEOUT, or from an earlier session) is taken over, never waited on
# for good (a save made inside Join or "wear this" whose stack an update dropped once hung every later Join).
lock = function('Lock')
check('Lock: waits at most LOCK_TIMEOUT and treats a lock from an earlier session as stale',
      'LOCK_TIMEOUT' in lock and 'now >= busyAt' in lock and 'busyAt = Utility.GetCurrentRealTime()' in lock, lock)
print(f'{fails} failed')
sys.exit(1 if fails else 0)
