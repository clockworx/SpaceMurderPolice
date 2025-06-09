extends Node
class_name DialogueSystem

# Dialogue data structure
var dialogues: Dictionary = {}
var current_dialogue: DialogueNode = null
var current_npc: NPCBase = null
var evidence_manager: EvidenceManager = null
var relationship_manager: RelationshipManager = null

signal dialogue_started(npc_name: String)
signal dialogue_ended()
signal dialogue_line_changed(speaker: String, text: String, options: Array)
signal evidence_revealed(evidence_id: String)
signal relationship_changed(npc_name: String, change: int)

class DialogueNode:
    var id: String
    var speaker: String
    var text: String
    var options: Array[DialogueOption] = []
    var evidence_required: String = ""  # Evidence ID needed to unlock this dialogue
    var evidence_revealed: String = ""  # Evidence ID to give player after this dialogue
    var relationship_change: int = 0    # How this dialogue affects relationship
    var min_relationship: int = -999    # Minimum relationship to access this dialogue
    var visited: bool = false
    
    func _init(p_id: String, p_speaker: String, p_text: String):
        id = p_id
        speaker = p_speaker
        text = p_text

class DialogueOption:
    var text: String
    var next_id: String
    var condition_type: String = ""  # "evidence", "visited", "relationship", "always"
    var condition_value: String = ""
    var relationship_change: int = 0  # How selecting this option affects relationship
    var decision_id: String = ""      # ID for tracking important decisions
    
    func _init(p_text: String, p_next_id: String):
        text = p_text
        next_id = p_next_id

func _ready():
    add_to_group("dialogue_system")
    
    # Get reference to managers
    evidence_manager = get_tree().get_first_node_in_group("evidence_manager")
    relationship_manager = get_tree().get_first_node_in_group("relationship_manager")
    
    # Create relationship manager if it doesn't exist
    if not relationship_manager:
        relationship_manager = RelationshipManager.new()
        get_tree().root.add_child.call_deferred(relationship_manager)
    
    # Initialize all dialogue trees
    _init_commander_chen_dialogue()
    _init_dr_webb_dialogue()
    _init_riley_kim_dialogue()
    _init_jake_torres_dialogue()
    _init_dr_okafor_dialogue()

func _init_commander_chen_dialogue():
    # Commander Sarah Chen - Red Herring (Financial troubles)
    var chen_intro = DialogueNode.new("chen_intro", "Commander Chen", 
        "Investigator. I'm Commander Chen. This is a disaster - Dr. Vasquez was one of our best. I need you to wrap this up quickly and quietly. The station's reputation is at stake.")
    chen_intro.options.append(DialogueOption.new("What happened to Dr. Vasquez?", "chen_accident"))
    chen_intro.options.append(DialogueOption.new("Tell me about the station.", "chen_station"))
    chen_intro.options.append(DialogueOption.new("Did Dr. Vasquez have any enemies?", "chen_enemies"))
    
    var chen_accident = DialogueNode.new("chen_accident", "Commander Chen",
        "Equipment malfunction in Lab 3. Electrical surge from the specimen containment unit. She was working late, alone. A tragic accident.")
    chen_accident.options.append(DialogueOption.new("Are you certain it was an accident?", "chen_defensive"))
    chen_accident.options.append(DialogueOption.new("Who found the body?", "chen_discovery"))
    
    var chen_defensive = DialogueNode.new("chen_defensive", "Commander Chen",
        "Of course it was an accident! What are you implying? We run a tight ship here. Safety protocols are followed to the letter.")
    var chen_thorough = DialogueOption.new("I'm just being thorough.", "chen_station")
    chen_thorough.relationship_change = 1  # Polite response improves relationship
    chen_defensive.options.append(chen_thorough)
    
    var chen_accuse = DialogueOption.new("The station seems to have financial troubles.", "chen_angry")
    chen_accuse.relationship_change = -2  # Accusatory response damages relationship
    chen_accuse.decision_id = "accused_chen_finances"
    chen_defensive.options.append(chen_accuse)
    
    var chen_angry = DialogueNode.new("chen_angry", "Commander Chen",
        "How dare you... Our funding situation has nothing to do with this! Yes, we've had budget cuts, but that doesn't mean we compromise on safety!")
    chen_angry.evidence_revealed = "chen_financial_stress"
    
    var chen_station = DialogueNode.new("chen_station", "Commander Chen",
        "Aurora Station is a xenobiology research facility. We study specimens from the outer colonies. Important work. Expensive work.")
    chen_station.options.append(DialogueOption.new("Expensive?", "chen_budget"))
    
    var chen_budget = DialogueNode.new("chen_budget", "Commander Chen",
        "Research isn't cheap. Equipment, personnel, containment... The board has been breathing down my neck about costs. But we manage.")
    
    var chen_enemies = DialogueNode.new("chen_enemies", "Commander Chen",
        "Enemies? No... Well, Dr. Webb wasn't fond of her success. Professional rivalry. But nothing serious. Check with the others if you must.")
    
    var chen_discovery = DialogueNode.new("chen_discovery", "Commander Chen",
        "Riley Kim, our tech specialist. She was doing morning maintenance rounds. Poor thing was quite shaken.")
    
    # Hostile version - won't cooperate
    var chen_hostile = DialogueNode.new("chen_hostile", "Commander Chen",
        "I have nothing more to say to you. Your accusations are baseless and insulting. This investigation is over as far as I'm concerned.")
    chen_hostile.min_relationship = -999  # Shows when relationship is hostile
    
    # Friendly version - shares more info
    var chen_friendly_info = DialogueNode.new("chen_friendly_info", "Commander Chen",
        "Look, between you and me... Elena had been acting strange lately. Secretive. She mentioned something about irregularities in the specimen logs.")
    chen_friendly_info.min_relationship = 1  # Only shows when friendly
    chen_friendly_info.evidence_revealed = "specimen_irregularities"
    
    # Store all Chen dialogues
    dialogues["chen_intro"] = chen_intro
    dialogues["chen_hostile"] = chen_hostile
    dialogues["chen_friendly_info"] = chen_friendly_info
    dialogues["chen_accident"] = chen_accident
    dialogues["chen_defensive"] = chen_defensive
    dialogues["chen_angry"] = chen_angry
    dialogues["chen_station"] = chen_station
    dialogues["chen_budget"] = chen_budget
    dialogues["chen_enemies"] = chen_enemies
    dialogues["chen_discovery"] = chen_discovery

func _init_dr_webb_dialogue():
    # Dr. Marcus Webb - Red Herring (Professional jealousy)
    var webb_intro = DialogueNode.new("webb_intro", "Dr. Webb",
        "Another investigator? I've already told security everything. Elena and I were colleagues. Professional colleagues.")
    webb_intro.options.append(DialogueOption.new("Tell me about Dr. Vasquez.", "webb_elena"))
    webb_intro.options.append(DialogueOption.new("I heard there was rivalry between you.", "webb_rivalry"))
    webb_intro.options.append(DialogueOption.new("Where were you last night?", "webb_alibi"))
    
    var webb_elena = DialogueNode.new("webb_elena", "Dr. Webb",
        "Brilliant scientist. Perhaps too brilliant for her own good. She took risks, pushed boundaries. Some of us prefer... safer approaches.")
    webb_elena.options.append(DialogueOption.new("What kind of risks?", "webb_risks"))
    
    var webb_risks = DialogueNode.new("webb_risks", "Dr. Webb",
        "She was obsessed with those outer colony specimens. Kept pushing for more dangerous experiments. I warned her about safety protocols.")
    
    var webb_rivalry = DialogueNode.new("webb_rivalry", "Dr. Webb",
        "Rivalry? That's a strong word. We had... philosophical differences. She got the grants, the recognition. I got to watch.")
    webb_rivalry.options.append(DialogueOption.new("That must have been frustrating.", "webb_bitter"))
    
    var webb_bitter = DialogueNode.new("webb_bitter", "Dr. Webb",
        "Frustrating? Try humiliating. Twenty years of research, and she swoops in with her radical theories... But I didn't kill her, if that's what you're thinking.")
    webb_bitter.evidence_revealed = "webb_jealousy"
    
    var webb_alibi = DialogueNode.new("webb_alibi", "Dr. Webb",
        "In my quarters, sleeping. Alone. I know that's not much of an alibi, but it's the truth.")
    
    dialogues["webb_intro"] = webb_intro
    dialogues["webb_elena"] = webb_elena
    dialogues["webb_risks"] = webb_risks
    dialogues["webb_rivalry"] = webb_rivalry
    dialogues["webb_bitter"] = webb_bitter
    dialogues["webb_alibi"] = webb_alibi

func _init_riley_kim_dialogue():
    # Riley Kim - The Killer (Nervous, deflecting)
    var riley_intro = DialogueNode.new("riley_intro", "Riley Kim",
        "Oh! You're the investigator. I... I'm still shaken up. Finding Dr. Vasquez like that... it was horrible.")
    riley_intro.options.append(DialogueOption.new("Take your time. Tell me what happened.", "riley_discovery"))
    riley_intro.options.append(DialogueOption.new("You maintain the equipment, right?", "riley_equipment"))
    riley_intro.options.append(DialogueOption.new("How well did you know Dr. Vasquez?", "riley_relationship"))
    
    var riley_discovery = DialogueNode.new("riley_discovery", "Riley Kim",
        "I was doing my morning rounds. Lab 3's containment unit had triggered an alert. When I got there... she was on the floor. The smell of burned circuits...")
    riley_discovery.options.append(DialogueOption.new("What kind of alert?", "riley_nervous"))
    
    var riley_nervous = DialogueNode.new("riley_nervous", "Riley Kim",
        "Oh, um... Power surge warning. Happens sometimes with older equipment. I mean, not often! Our safety record is excellent!")
    
    var riley_equipment = DialogueNode.new("riley_equipment", "Riley Kim",
        "Yes, I handle all technical maintenance. I checked that unit just last week. Everything was functioning perfectly. These accidents... they shouldn't happen.")
    riley_equipment.options.append(DialogueOption.new("But it did happen.", "riley_defensive"))
    
    var riley_defensive = DialogueNode.new("riley_defensive", "Riley Kim",
        "Equipment fails sometimes! It's not... I do my job properly. Maybe if the station had better funding for replacements...")
    
    var riley_relationship = DialogueNode.new("riley_relationship", "Riley Kim",
        "Dr. Vasquez was... demanding. Always pushing for more power to her experiments. I told her the systems had limits, but she never listened.")
    riley_relationship.options.append(DialogueOption.new("Did you argue about it?", "riley_argument"))
    
    var riley_argument = DialogueNode.new("riley_argument", "Riley Kim",
        "Argue? No... I mean, we discussed it. She could be frustrating. But I respected her work. We all did.")
    
    # Evidence-locked dialogue
    var riley_confrontation = DialogueNode.new("riley_confrontation", "Riley Kim",
        "Those communications? I... I can explain! It's not what it looks like!")
    riley_confrontation.evidence_required = "black_market_communications"
    riley_confrontation.options.append(DialogueOption.new("Then explain.", "riley_confession"))
    
    var riley_confession = DialogueNode.new("riley_confession", "Riley Kim",
        "I needed the money! The specimens she worked with... they're worth fortunes on the black market. I just took samples, I never meant... It was supposed to look like an accident!")
    
    # Hostile version - becomes defensive
    var riley_hostile = DialogueNode.new("riley_hostile", "Riley Kim",
        "I... I don't have to talk to you! You're just trying to pin this on someone. Leave me alone!")
    riley_hostile.min_relationship = -999
    
    # Friendly version - drops hints
    var riley_friendly = DialogueNode.new("riley_friendly", "Riley Kim",
        "You seem trustworthy... Just be careful who you trust here. Not everyone is who they seem to be.")
    riley_friendly.min_relationship = 1
    var riley_hint = DialogueOption.new("What do you mean?", "riley_hint_detail")
    riley_hint.condition_type = "relationship"
    riley_hint.condition_value = "1"
    riley_friendly.options.append(riley_hint)
    
    var riley_hint_detail = DialogueNode.new("riley_hint_detail", "Riley Kim",
        "I've seen things... financial irregularities. Equipment that goes missing. But I keep my head down. It's safer that way.")
    
    dialogues["riley_intro"] = riley_intro
    dialogues["riley_hostile"] = riley_hostile
    dialogues["riley_friendly"] = riley_friendly
    dialogues["riley_hint_detail"] = riley_hint_detail
    dialogues["riley_discovery"] = riley_discovery
    dialogues["riley_nervous"] = riley_nervous
    dialogues["riley_equipment"] = riley_equipment
    dialogues["riley_defensive"] = riley_defensive
    dialogues["riley_relationship"] = riley_relationship
    dialogues["riley_argument"] = riley_argument
    dialogues["riley_confrontation"] = riley_confrontation
    dialogues["riley_confession"] = riley_confession

func _init_jake_torres_dialogue():
    # Jake Torres - Security Chief (Gruff, unhelpful)
    var jake_intro = DialogueNode.new("jake_intro", "Jake Torres",
        "Station Security. Name's Torres. Another investigator, huh? Waste of time if you ask me. Accident's an accident.")
    jake_intro.options.append(DialogueOption.new("You don't think it's worth investigating?", "jake_suspicious"))
    jake_intro.options.append(DialogueOption.new("Tell me about station security.", "jake_security"))
    jake_intro.options.append(DialogueOption.new("What was your relationship with Dr. Vasquez?", "jake_conflict"))
    
    var jake_suspicious = DialogueNode.new("jake_suspicious", "Jake Torres",
        "Look, I've been doing security for 15 years. I know an accident when I see one. But sure, waste everyone's time playing detective.")
    var jake_respect = DialogueOption.new("I respect your experience, but I need to be thorough.", "jake_cooperative")
    jake_respect.relationship_change = 2  # Shows respect improves relationship significantly
    jake_suspicious.options.append(jake_respect)
    
    var jake_dismiss = DialogueOption.new("Your opinion doesn't matter. I'm here to investigate.", "jake_offended")
    jake_dismiss.relationship_change = -2  # Dismissive response damages relationship
    jake_dismiss.decision_id = "dismissed_jake"
    jake_suspicious.options.append(jake_dismiss)
    
    var jake_cooperative = DialogueNode.new("jake_cooperative", "Jake Torres",
        "Well... when you put it that way. Look, I'll help however I can. Just don't expect me to believe this was anything but an accident.")
    
    var jake_offended = DialogueNode.new("jake_offended", "Jake Torres",
        "Real professional. You wonder why nobody wants to cooperate with investigators? This is why.")
    jake_offended.relationship_change = -1  # Further damages relationship
    
    var jake_security = DialogueNode.new("jake_security", "Jake Torres",
        "I monitor access logs, camera feeds, the usual. Nothing suspicious lately. Well, except for Dr. Vasquez working late again.")
    jake_security.options.append(DialogueOption.new("She worked late often?", "jake_schedule"))
    
    var jake_schedule = DialogueNode.new("jake_schedule", "Jake Torres",
        "All the time. Obsessed with her work. I told her it wasn't safe, working alone at night. But did she listen? Scientists never do.")
    
    var jake_conflict = DialogueNode.new("jake_conflict", "Jake Torres",
        "We didn't see eye to eye. She thought security was an inconvenience. Kept complaining about access restrictions. We had... words about it.")
    jake_conflict.options.append(DialogueOption.new("What kind of words?", "jake_argument"))
    
    var jake_argument = DialogueNode.new("jake_argument", "Jake Torres",
        "Professional disagreement. She wanted unrestricted access to everything. I said no. She went over my head to Chen. I was overruled. End of story.")
    jake_argument.evidence_revealed = "jake_elena_conflict"
    
    # Hostile version - refuses to cooperate
    var jake_hostile = DialogueNode.new("jake_hostile", "Jake Torres",
        "Get out of my sight. I'm done talking to you. File a complaint if you want - I don't care.")
    
    # Friendly version - shares crucial security info
    var jake_friendly_info = DialogueNode.new("jake_friendly_info", "Jake Torres",
        "Since you've been straight with me... I saw something odd on the cameras. Riley was near Lab 3 around 2 AM that night. Way outside her normal rounds.")
    jake_friendly_info.min_relationship = 1
    jake_friendly_info.evidence_revealed = "riley_suspicious_activity"
    jake_friendly_info.options.append(DialogueOption.new("Did you report this?", "jake_coverup"))
    
    var jake_coverup = DialogueNode.new("jake_coverup", "Jake Torres",
        "I... no. Riley's a good kid. I figured she had a reason. Maybe I should have said something.")
    
    dialogues["jake_intro"] = jake_intro
    dialogues["jake_hostile"] = jake_hostile
    dialogues["jake_friendly_info"] = jake_friendly_info
    dialogues["jake_coverup"] = jake_coverup
    dialogues["jake_cooperative"] = jake_cooperative
    dialogues["jake_offended"] = jake_offended
    dialogues["jake_suspicious"] = jake_suspicious
    dialogues["jake_security"] = jake_security
    dialogues["jake_schedule"] = jake_schedule
    dialogues["jake_conflict"] = jake_conflict
    dialogues["jake_argument"] = jake_argument

func _init_dr_okafor_dialogue():
    # Dr. Zara Okafor - Medical Officer (Helpful witness)
    var okafor_intro = DialogueNode.new("okafor_intro", "Dr. Okafor",
        "Investigator, I'm Dr. Okafor, the station's medical officer. I performed the preliminary examination. There's something you should know.")
    okafor_intro.options.append(DialogueOption.new("What did you find?", "okafor_medical"))
    okafor_intro.options.append(DialogueOption.new("Did you know Dr. Vasquez well?", "okafor_relationship"))
    
    var okafor_medical = DialogueNode.new("okafor_medical", "Dr. Okafor",
        "The burn patterns... they're inconsistent with a simple equipment malfunction. The electrical discharge was too focused, too precise.")
    okafor_medical.options.append(DialogueOption.new("What are you saying?", "okafor_suspicious"))
    okafor_medical.evidence_revealed = "medical_evidence_murder"
    
    var okafor_suspicious = DialogueNode.new("okafor_suspicious", "Dr. Okafor",
        "I'm saying this might not have been an accident. Someone with technical knowledge could have modified that equipment. But I'm just a doctor, not a detective.")
    okafor_suspicious.options.append(DialogueOption.new("Who has that kind of knowledge?", "okafor_suspects"))
    
    var okafor_suspects = DialogueNode.new("okafor_suspects", "Dr. Okafor",
        "Riley Kim handles all our technical systems. She's brilliant with electronics. Jake knows the security systems. Even Dr. Webb has some engineering background.")
    
    var okafor_relationship = DialogueNode.new("okafor_relationship", "Dr. Okafor",
        "Elena was passionate about her work. Maybe too passionate. She'd been acting strange lately - secretive, paranoid. Said she'd discovered something important.")
    okafor_relationship.options.append(DialogueOption.new("What kind of discovery?", "okafor_discovery"))
    
    var okafor_discovery = DialogueNode.new("okafor_discovery", "Dr. Okafor",
        "She wouldn't say. But she was nervous, kept looking over her shoulder. Asked me about secure communication channels. I wish I'd pressed her for details.")
    
    dialogues["okafor_intro"] = okafor_intro
    dialogues["okafor_medical"] = okafor_medical
    dialogues["okafor_suspicious"] = okafor_suspicious
    dialogues["okafor_suspects"] = okafor_suspects
    dialogues["okafor_relationship"] = okafor_relationship
    dialogues["okafor_discovery"] = okafor_discovery

func _init_unknown_figure_dialogue():
    # Dialogue for when player encounters Riley in saboteur mode
    var unknown_intro = DialogueNode.new("unknown_intro", "Unknown Figure",
        "...")
    unknown_intro.options.append(DialogueOption.new("Who are you?", "unknown_silent"))
    unknown_intro.options.append(DialogueOption.new("What are you doing here?", "unknown_leave"))
    unknown_intro.options.append(DialogueOption.new("Stop right there!", "unknown_flee"))
    
    var unknown_silent = DialogueNode.new("unknown_silent", "Unknown Figure",
        "[The figure remains silent, their face obscured by a dark helmet]")
    unknown_silent.options.append(DialogueOption.new("I said, who are you?!", "unknown_leave"))
    unknown_silent.options.append(DialogueOption.new("[Try to get closer]", "unknown_flee"))
    
    var unknown_leave = DialogueNode.new("unknown_leave", "Unknown Figure",
        "[The figure turns away, moving quickly toward the exit]")
    unknown_leave.options.append(DialogueOption.new("[Follow them]", "unknown_gone"))
    unknown_leave.options.append(DialogueOption.new("[Let them go]", "unknown_gone"))
    
    var unknown_flee = DialogueNode.new("unknown_flee", "Unknown Figure",
        "[The figure suddenly bolts, disappearing into the shadows]")
    unknown_flee.options.append(DialogueOption.new("[Give chase]", "unknown_gone"))
    unknown_flee.options.append(DialogueOption.new("[Stay and investigate]", "unknown_gone"))
    
    var unknown_gone = DialogueNode.new("unknown_gone", "System",
        "[The mysterious figure has vanished. You notice they were near the power control panel...]")
    
    dialogues["unknown_intro"] = unknown_intro
    dialogues["unknown_silent"] = unknown_silent
    dialogues["unknown_leave"] = unknown_leave
    dialogues["unknown_flee"] = unknown_flee
    dialogues["unknown_gone"] = unknown_gone

func start_dialogue(npc: NPCBase, dialogue_id: String = ""):
    if not npc:
        return
        
    current_npc = npc
    
    # Check if NPC has character modes (for Riley saboteur mode)
    var character_modes = npc.get_node_or_null("RileyCharacterModes")
    var effective_npc_name = npc.npc_name
    
    if character_modes and character_modes.has_method("is_in_saboteur_mode") and character_modes.is_in_saboteur_mode():
        # Initialize saboteur dialogue if not already done
        if not dialogues.has("unknown_intro"):
            _init_unknown_figure_dialogue()
        effective_npc_name = "Unknown Figure"
    
    var start_id = dialogue_id if dialogue_id != "" else _get_npc_start_dialogue(effective_npc_name)
    
    # Check for relationship-based alternative start
    if relationship_manager and effective_npc_name != "Unknown Figure":
        if relationship_manager.is_hostile(effective_npc_name):
            # Try to find hostile version
            var hostile_id = _get_hostile_dialogue_id(effective_npc_name)
            if dialogues.has(hostile_id):
                start_id = hostile_id
    
    if dialogues.has(start_id):
        current_dialogue = dialogues[start_id]
        current_dialogue.visited = true
        dialogue_started.emit(effective_npc_name)
        _display_current_dialogue()
    else:
        push_error("Dialogue not found: " + start_id)

func _get_npc_start_dialogue(npc_name: String) -> String:
    match npc_name:
        "Commander Sarah Chen", "Commander Chen":
            return "chen_intro"
        "Dr. Marcus Webb", "Dr. Webb":
            return "webb_intro"
        "Riley Kim":
            return "riley_intro"
        "Jake Torres", "Officer Marcus Johnson":
            return "jake_intro"
        "Dr. Zara Okafor", "Dr. Sarah Chen":
            return "okafor_intro"
        "Unknown Figure":
            return "unknown_intro"
        _:
            return "chen_intro"  # Default fallback

func _display_current_dialogue():
    if not current_dialogue or not current_npc:
        return
    
    # Check if player meets relationship requirements
    if relationship_manager and current_dialogue.min_relationship > -999:
        var current_rel = relationship_manager.get_relationship(current_npc.npc_name)
        if current_rel < current_dialogue.min_relationship:
            # Find alternative dialogue based on relationship
            if relationship_manager.is_hostile(current_npc.npc_name):
                var hostile_id = _get_hostile_dialogue_id(current_npc.npc_name)
                if dialogues.has(hostile_id):
                    current_dialogue = dialogues[hostile_id]
    
    # Check for special dialogue conditions
    if relationship_manager and relationship_manager.is_friendly(current_npc.npc_name):
        # Check if there's a friendly version available
        var friendly_id = current_dialogue.id.replace("intro", "friendly_info")
        if dialogues.has(friendly_id) and not dialogues[friendly_id].visited:
            # Add option to access friendly dialogue
            var friendly_opt = DialogueOption.new("I'd like your honest opinion...", friendly_id)
            friendly_opt.condition_type = "relationship"
            friendly_opt.condition_value = "1"
            if not _option_exists(current_dialogue.options, friendly_id):
                current_dialogue.options.append(friendly_opt)
    
    var available_options = []
    for option in current_dialogue.options:
        if _check_option_condition(option):
            available_options.append(option.text)
    
    # Add a default exit option
    available_options.append("[Leave conversation]")
    
    dialogue_line_changed.emit(
        current_dialogue.speaker,
        current_dialogue.text,
        available_options
    )
    
    # Handle evidence revelation
    if current_dialogue.evidence_revealed != "":
        evidence_revealed.emit(current_dialogue.evidence_revealed)

func _option_exists(options: Array, next_id: String) -> bool:
    for opt in options:
        if opt.next_id == next_id:
            return true
    return false

func _check_option_condition(option: DialogueOption) -> bool:
    match option.condition_type:
        "evidence":
            return evidence_manager and evidence_manager.has_evidence(option.condition_value)
        "visited":
            return dialogues.has(option.condition_value) and dialogues[option.condition_value].visited
        "relationship":
            if not relationship_manager or not current_npc:
                return false
            var rel_level = int(option.condition_value)
            return relationship_manager.get_relationship(current_npc.npc_name) >= rel_level
        _:
            return true  # Always show if no condition

func _get_hostile_dialogue_id(npc_name: String) -> String:
    match npc_name:
        "Commander Chen":
            return "chen_hostile"
        "Dr. Webb":
            return "webb_hostile"
        "Riley Kim":
            return "riley_hostile"
        "Jake Torres":
            return "jake_hostile"
        _:
            return ""

func select_option(option_index: int):
    if not current_dialogue or not current_npc:
        return
    
    var available_options = []
    for option in current_dialogue.options:
        if _check_option_condition(option):
            available_options.append(option)
    
    if option_index == available_options.size():  # Exit option
        end_dialogue()
        return
    
    if option_index < available_options.size():
        var selected = available_options[option_index]
        
        # Apply relationship change
        if selected.relationship_change != 0 and relationship_manager:
            relationship_manager.modify_relationship(current_npc.npc_name, selected.relationship_change)
            print("Relationship with ", current_npc.npc_name, " changed by ", selected.relationship_change)
            relationship_changed.emit(current_npc.npc_name, selected.relationship_change)
        
        # Record important decision
        if selected.decision_id != "" and relationship_manager:
            relationship_manager.record_decision(selected.decision_id, true)
        
        # Move to next dialogue
        if dialogues.has(selected.next_id):
            current_dialogue = dialogues[selected.next_id]
            current_dialogue.visited = true
            
            # Apply any relationship changes from the new dialogue node
            if current_dialogue.relationship_change != 0:
                relationship_manager.modify_relationship(current_npc.npc_name, current_dialogue.relationship_change)
                relationship_changed.emit(current_npc.npc_name, current_dialogue.relationship_change)
            
            _display_current_dialogue()
        else:
            end_dialogue()

func end_dialogue():
    dialogue_ended.emit()
    if current_npc:
        current_npc.end_dialogue()
    current_npc = null
    current_dialogue = null
