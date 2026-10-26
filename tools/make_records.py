"""Writes the Followers module's plugin as Spriggit YAML (one quest running MLWF_Main) and its Mantella action
files. Run from the project root."""
import json, os

E = 'Mantella Living World - Followers.esp'


def write(path, text):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    open(path, 'w', encoding='utf-8', newline='\n').write(text)


write(f'esp/Quests/MLWF_Quest - 000800_{E}.yaml',
      f"FormKey: 000800:{E}\nEditorID: MLWF_Quest\nVirtualMachineAdapter:\n  Scripts:\n  - Name: MLWF_Main\n    Properties:\n"
      f"    - MutagenObjectType: ScriptObjectProperty\n      Name: PlayerRef\n      Object: 000014:Skyrim.esm\n  FileName: ''\n"
      f"Name:\n  TargetLanguage: English\n  Value: Mantella Living World - Followers\nFlags:\n- StartGameEnabled\nNextAliasID: 0\n")
write('esp/RecordData.yaml', f'ModKey: {E}\nGameRelease: SkyrimSE\nModHeader:\n  Flags:\n  - Small\n  Author: itsPigeon2000\n'
      '  Description: Mantella Living World - Followers. Mantella actions for Nether\'s Follower Framework.\n'
      '  MasterReferences:\n  - Master: Skyrim.esm\n    FileSize: 0\n')
write('esp/spriggit-meta.json', json.dumps({'PackageName': 'Spriggit.Yaml.Skyrim', 'Version': '0.40.0', 'Release': 'SkyrimSE', 'ModKey': E}, indent=2))

NOTE = 'Needs Mantella Living World - Followers and Nether\'s Follower Framework. Turn off Mantella\'s own Follow, Unfollow and Wait.'
SOURCE = {'source': {'type': 'array', 'description': 'The NPC(s) this applies to.', 'items': {'type': 'string'}, 'scope': 'conversation'}}
ACTIONS = [
    ('join', 'JoinParty', 'Make NPC(s) join the player\'s party as followers.',
     "If the player asks you to follow them, travel with them or join their party, and you are thoroughly convinced to do so, begin your response with '{key}:'", True),
    ('leave', 'LeaveParty', 'Make NPC(s) leave the player\'s party.',
     "If the player tells you to stop following them, go home or leave their party, or you decide to leave the party yourself, begin your response with '{key}:'", True),
    ('wait', 'WaitHere', 'Make follower(s) wait at their current spot.',
     "If you follow the player and they ask you to wait, stay or hold here, begin your response with '{key}:'", True),
    ('follow', 'FollowMe', 'Make waiting follower(s) follow the player again.',
     "If you are waiting for the player and they ask you to come along or follow them again, begin your response with '{key}:'", True),
    ('wait_all', 'EveryoneWait', 'Make the whole party wait here.',
     "If the player tells the whole party or everyone to wait or stay here, begin your response with '{key}:'", False),
    ('follow_all', 'EveryoneFollow', 'Make the whole party follow the player again.',
     "If the player tells the whole party or everyone to follow them again, begin your response with '{key}:'", False),
    ('passive', 'StayPassive', 'Make follower(s) stay out of fights.',
     "If the player asks you to stay out of fights, keep your weapons away or stop fighting, begin your response with '{key}:'", True),
    ('aggressive', 'FightFreely', 'Make follower(s) fight enemies and help in fights again.',
     "If the player asks you to fight, attack enemies on sight or join their fights again, begin your response with '{key}:'", True),
    ('wear', 'WearThis', 'Open the trade window so the player can hand clothes to wear; the NPC keeps them as an outfit.',
     "If the player wants to give you clothes or armor to wear, or asks you to change into something they hand you, begin your response with '{key}:'", True),
]
for ident, name, desc, prompt, takes_source in ACTIONS:
    data = {'identifier': f'mantella_mlw_{ident}', 'name': name, 'description': desc, 'note': NOTE, 'key': name, 'enabled': True}
    if takes_source:
        data['parameters'] = SOURCE
        data['required'] = ['source']
    data.update({'prompt': prompt, 'allowed_games': ['skyrim'], 'requires_response': False, 'is-interrupting': False,
                 'allow_repeat': False, 'one-on-one': True, 'multi-npc': True, 'radiant': False})
    write(f'SKSE/Plugins/MantellaSoftware/data/actions/mantella_mlw_{ident}.json', json.dumps(data, indent=4) + '\n')
print('followers records written:', len(ACTIONS), 'actions')
