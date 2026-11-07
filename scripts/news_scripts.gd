extends RefCounted
## PNN, the Plastic News Network. Parody news breaks shown before and after
## each operation. House style: silly for kids, with a dry grown-up undertone
## (budgets, Wi-Fi, family dinners, office life). Keep it clean: no swearing,
## nothing scary, no real people or real places.
##
## A script is {"theme", "ticker": [..], "beats": [{"who", "line", "headline"?, "gesture"?}]}.
## who: "chip" (anchor), "brenda" (co-anchor), "gary" (field reporter), "both" (wide shot).
## {kills}, {total}, {time}, {headshots}, {accuracy} are filled in from mission stats.

const THEMES := ["desert", "city", "table", "snow", "jungle", "bath", "beach", "yard", "port", "bedroom", "mountain", "garage", "couch"]
const PLACES := ["the desert", "Port Varos", "the kitchen table", "the polar shelf", "the jungle", "the bathroom", "the Crumb Coast",
    "the backyard", "Port Ochre", "the bedroom", "Biscuit Pass", "the garage", "the living room"]


static func intro(op: int) -> Dictionary:
    if op >= 3 and op - 3 < MORE_INTROS.size():
        return MORE_INTROS[op - 3].duplicate(true)
    match op:
        0:
            return {
                "theme": "desert",
                "ticker": [
                    "SANDBAG SHORTAGE BLAMED ON 'SANDBAG HOARDERS'",
                    "LOCAL SCORPION UNIMPRESSED BY ALL OF THIS",
                    "WEATHER: HOT, THEN HOTTER, THEN 'WHY DO WE EVEN LIVE HERE'",
                    "PNN POLL: 9 OUT OF 10 TOY SOLDIERS PREFER NOT TO BE STEPPED ON",
                ],
                "beats": [
                    {"who": "both", "line": "This is PNN, the Plastic News Network. All the news that's fit to mold.", "headline": "PNN EVENING NEWS"},
                    {"who": "chip", "line": "Good evening. I'm Chip Plasterson, and I have been molded exactly like this since 1962.", "gesture": "Wave"},
                    {"who": "brenda", "line": "And I'm Brenda Mold. Tonight: the Tan Army has set up radar jammers in the desert.", "headline": "TAN ARMY JAMS DESERT; ALL DRONES, WI-FI GO DARK"},
                    {"who": "brenda", "line": "The jammers have knocked out every drone, every radio, and three separate dads trying to stream the big game."},
                    {"who": "chip", "line": "Experts say the jammers can only be stopped with explosives. When asked for comment, the jammers said nothing. Because they were jamming.", "gesture": "Yes"},
                    {"who": "gary", "line": "Chip, I'm live at Forward Operating Base Juliet, where morale is high and the sand is everywhere. I found sand in my sand.", "headline": "LIVE: FOB JULIET"},
                    {"who": "gary", "line": "Command is sending in one green soldier to fix all of this. When I asked why just one, a spokesman said, quote, 'Budget.'"},
                    {"who": "chip", "line": "One soldier against an entire army. Brenda, is that a good plan?", "headline": "COMMAND: 'ONE GUY IS PLENTY, PROBABLY'"},
                    {"who": "brenda", "line": "It's the plan we could afford, Chip.", "gesture": "No"},
                ],
            }
        1:
            return {
                "theme": "city",
                "ticker": [
                    "PARKING TICKETS NOW PAYABLE ONLY IN BEIGE",
                    "LOCAL PIGEONS REFUSE TO PICK A SIDE",
                    "TRAFFIC: TANK ON 5TH STREET. ALSO A TANK ON 6TH STREET",
                    "CITY COUNCIL MEETING CANCELLED; NOBODY NOTICED",
                ],
                "beats": [
                    {"who": "chip", "line": "Our top story tonight comes from Port Varos, where Tan Army Colonel Khaki has taken over the city plaza.", "headline": "COLONEL KHAKI SEIZES PLAZA"},
                    {"who": "brenda", "line": "The Colonel has renamed every street in the city 'Khaki Street.' Residents report getting lost. The Colonel reports this is, quote, 'a them problem.'", "headline": "EVERY STREET NOW 'KHAKI STREET'"},
                    {"who": "chip", "line": "He has also declared himself Mayor, King, and head of Parking Enforcement. That last one, honestly, nobody wanted.", "gesture": "No"},
                    {"who": "gary", "line": "Chip, I'm downtown, where Tan missile launchers have grounded all air support. And all kites. A little boy here would like his kite back.", "headline": "LIVE: DOWNTOWN PORT VAROS"},
                    {"who": "gary", "line": "Also, watch the rooftops. Tan snipers are up there, and they've been up there for a while. One of them asked me if I had snacks."},
                    {"who": "brenda", "line": "Colonel Khaki says he is 'not afraid of one small green man.' Sources confirm he has checked under his bed four times tonight.", "headline": "COLONEL 'NOT SCARED,' SAYS SCARED COLONEL"},
                    {"who": "chip", "line": "Our green soldier is on his way. He was last seen eating a protein bar and looking very determined.", "gesture": "Yes"},
                ],
            }
        2:
            return {
                "theme": "table",
                "ticker": [
                    "GIANT PENCIL DECLARED A NATIONAL MONUMENT",
                    "CEREAL BOX'S 'PART OF A BALANCED BREAKFAST' CLAIM UNDER INVESTIGATION",
                    "PHONE AT 3% BATTERY; NOBODY WILL SAY WHOSE IT IS",
                    "SCIENTISTS: THE COFFEE MUG 'HAS SEEN THINGS'",
                ],
                "beats": [
                    {"who": "chip", "line": "Tonight's top story is happening on a kitchen table. Which, let's be honest, is where most big decisions in this country get made anyway.", "headline": "TAN ARMY SEIZES KITCHEN TABLE"},
                    {"who": "brenda", "line": "The Tan Army has wired three signal boosters into the house Wi-Fi. Their demands: total victory, and the Wi-Fi password.", "headline": "TAN DEMANDS: VICTORY, WI-FI PASSWORD"},
                    {"who": "chip", "line": "The password, for the record, is on a sticky note on the fridge. Like everyone's.", "gesture": "Yes"},
                    {"who": "gary", "line": "Chip, I'm live next to a can of energy drink the size of an office building. I've been standing here forty minutes, and my heart is going very fast. Probably unrelated.", "headline": "LIVE: THE KITCHEN TABLE"},
                    {"who": "brenda", "line": "We reached out to the humans who own the table. They're asleep, and also apparently cannot see any of this. Classic humans.", "gesture": "No"},
                    {"who": "chip", "line": "This is the big one, folks. Family dinner has been postponed until further notice. Stay tuned.", "headline": "FAMILY DINNER POSTPONED INDEFINITELY"},
                ],
            }
    return intro(0)


static func outro(op: int, success: bool, stats: Dictionary) -> Dictionary:
    var d: Dictionary
    if not success:
        d = _fail(op)
    elif op >= 3 and op - 3 < MORE_OUTROS.size():
        d = MORE_OUTROS[op - 3].duplicate(true)
    else:
        match op:
            0:
                d = {
                    "theme": "desert",
                    "ticker": [
                        "DESERT WI-FI RESTORED; FAMILIES RETURN TO IGNORING EACH OTHER",
                        "SCORPION STILL UNIMPRESSED",
                        "JAMMER SPARE PARTS NOW AVAILABLE AT HALF PRICE",
                    ],
                    "beats": [
                        {"who": "chip", "line": "Breaking news: all three radar jammers are down!", "headline": "JAMMERS DOWN! WI-FI IS BACK!", "gesture": "Wave"},
                        {"who": "brenda", "line": "Within seconds the desert Wi-Fi was back, and every family immediately went back to not talking at dinner.", "headline": "NATION RETURNS TO STARING AT PHONES"},
                        {"who": "chip", "line": "Our green soldier melted {kills} Tan troops in {time}. Command called it 'very efficient,' and then asked if he could also do their taxes."},
                        "STATS",
                        {"who": "gary", "line": "Chip, the extraction helicopter is here to pick him up. And also me? No? Okay. I'll walk. It's only a hundred miles.", "headline": "LIVE: THE HELIPAD"},
                    ],
                }
            1:
                d = {
                    "theme": "city",
                    "ticker": [
                        "ALL STREETS RENAMED BACK; PEOPLE STILL LOST, BUT NORMALLY",
                        "KITE RETURNED TO GRATEFUL CHILD",
                        "PIGEONS TAKE CREDIT FOR EVERYTHING",
                    ],
                    "beats": [
                        {"who": "chip", "line": "Colonel Khaki has been melted. City workers say the plaza fountain will need a good cleaning, and possibly some therapy.", "headline": "COLONEL KHAKI MELTS; FOUNTAIN NOW 'MOSTLY COLONEL'"},
                        {"who": "brenda", "line": "Both missile launchers are destroyed and air support is back. So are the kites. The kid got his kite.", "headline": "AIR SUPPORT BACK. KITES TOO.", "gesture": "Yes"},
                        "STATS",
                        {"who": "gary", "line": "Chip, the parking tickets have all been cancelled! People are dancing in the street! Well, one guy is. He might just be cold.", "headline": "LIVE: CITY CELEBRATES, MOSTLY"},
                        {"who": "chip", "line": "And Colonel Khaki's official portrait has been taken down. It was mostly a picture of his own mustache."},
                    ],
                }
            _:
                d = {
                    "theme": "table",
                    "ticker": [
                        "CAT HIRES LAWYER",
                        "FAMILY DINNER BACK ON; MEATLOAF, UNFORTUNATELY",
                        "THANK YOU FOR WATCHING PNN. PLEASE DON'T LEAVE YOUR TOYS ON THE TABLE",
                    ],
                    "beats": [
                        {"who": "chip", "line": "The table is clear! Every last Tan soldier has been melted.", "headline": "TABLE LIBERATED!", "gesture": "Wave"},
                        {"who": "brenda", "line": "When the humans woke up, they found tiny puddles of plastic everywhere, and they blamed the cat.", "headline": "HUMANS WAKE, BLAME CAT"},
                        {"who": "chip", "line": "The cat has hired a lawyer.", "headline": "CAT HIRES LAWYER", "gesture": "Yes"},
                        "STATS",
                        {"who": "gary", "line": "Chip, it's been an incredible campaign, and I just want to say something to my family at home. Mom, I'm finally on TV, I-", "headline": "LIVE: THE KITCHEN TABLE"},
                        {"who": "chip", "line": "And we're out of time.", "gesture": "No"},
                        {"who": "brenda", "line": "One more thing, Chip. A Tan defector says the army has a new leader, a General Beige, and he's heading north.", "headline": "DEVELOPING: WHO IS GENERAL BEIGE?"},
                        {"who": "chip", "line": "Then so are we. Goodnight, everybody. Pack a coat.", "headline": "PNN: THIS ISN'T OVER"},
                    ],
                }
    # Replace the "STATS" marker with a line chosen from how the mission went.
    var beats: Array = []
    for b in d["beats"]:
        if b is String and b == "STATS":
            beats.append(_stats_beat(stats))
        else:
            beats.append(b)
    d["beats"] = beats
    return fill(d, stats)


static func _stats_beat(stats: Dictionary) -> Dictionary:
    var acc: float = stats.get("accuracy", 0.0)
    var hs: int = stats.get("headshots", 0)
    var secs: float = stats.get("time", 0.0)
    if hs >= 8:
        return {"who": "brenda", "line": "He landed {headshots} headshots. Tan Army helmet sales are up four hundred percent.", "headline": "TAN HELMET SALES SKYROCKET"}
    if acc < 30.0:
        return {"who": "brenda", "line": "Witnesses say he fired a lot of bullets. Experts estimate {accuracy} percent of them were on purpose.", "headline": "EXPERTS: 'HE SURE SHOT A LOT'"}
    if acc > 60.0:
        return {"who": "brenda", "line": "His accuracy was {accuracy} percent. Tan soldiers describe him as 'rude' and 'very, very good at aiming.'", "headline": "TAN ARMY FILES COMPLAINT"}
    if secs < 300.0:
        return {"who": "brenda", "line": "The whole thing took {time}. That's faster than most people take to pick a show to watch.", "headline": "RECORD TIME, SAY EXPERTS"}
    return {"who": "brenda", "line": "It took {time}, which officials call 'about what we budgeted,' which is to say, not much.", "headline": "MISSION 'ON BUDGET,' SAYS BUDGET"}


static func _fail(op: int) -> Dictionary:
    var place: String = PLACES[clampi(op, 0, PLACES.size() - 1)]
    return {
        "theme": THEMES[clampi(op, 0, THEMES.size() - 1)],
        "ticker": [
            "COMMAND: 'HAVE YOU TRIED TURNING HIM OFF AND ON AGAIN?'",
            "PLASTIC PUDDLE EXPERTS IN HIGH DEMAND",
            "TAN ARMY HOLDS VICTORY PARTY; SNACKS DESCRIBED AS 'BEIGE'",
        ],
        "beats": [
            {"who": "chip", "line": "Some bad news from %s tonight. Our green soldier has melted into what experts are calling 'a very flat situation.'" % place, "headline": "GREEN SOLDIER MELTS", "gesture": "No"},
            {"who": "brenda", "line": "Command says a replacement is already on the way. The replacement is the same guy. Nobody can explain this.", "headline": "REPLACEMENT EN ROUTE; IT'S THE SAME GUY"},
            {"who": "gary", "line": "Chip, the Tan Army is throwing a victory party out here. They invited me. The snacks are all beige. I'm not having a great time.", "headline": "LIVE: TAN VICTORY PARTY"},
            {"who": "chip", "line": "We'll be right back after these messages. Probably. Budget permitting."},
        ],
    }


## Fills {placeholders} in every line and headline.
static func fill(d: Dictionary, stats: Dictionary) -> Dictionary:
    var secs := int(stats.get("time", 0.0))
    var subs := {
        "{kills}": str(stats.get("kills", 0)),
        "{total}": str(stats.get("total", 0)),
        "{headshots}": str(stats.get("headshots", 0)),
        "{accuracy}": str(int(stats.get("accuracy", 0.0))),
        "{time}": ("%d minutes and %d seconds" % [secs / 60, secs % 60]) if secs >= 60 else ("%d seconds" % secs),
    }
    for b in d["beats"]:
        for key in ["line", "headline"]:
            if b.has(key):
                var t: String = b[key]
                for k in subs:
                    t = t.replace(k, subs[k])
                b[key] = t
    return d


# ---------------------------------------------------- ops 4-13 (index 3-12) ----

const MORE_INTROS := [
    {   # 3 Snow Globe
        "theme": "snow",
        "ticker": [
            "POLAR SHELF TEMPERATURE: 'NOPE'",
            "PENGUIN SPOKESMAN: 'WE ARE NOT INVOLVED IN THIS'",
            "HOT COCOA PRICES SOAR; MARSHMALLOW ANALYSTS CAUTIOUS",
            "SCIENTISTS CONFIRM PLASTIC GETS 'EXTRA SNAPPY' IN THE COLD",
        ],
        "beats": [
            {"who": "chip", "line": "Good evening. After the battle of the kitchen table, the Tan Army has fled north. Way north. Freezer north.", "headline": "TAN ARMY FLEES TO THE ARCTIC"},
            {"who": "brenda", "line": "A defector says they have a new leader: General Beige. Nobody has seen him, but everyone agrees he sounds very boring.", "headline": "WHO IS GENERAL BEIGE?"},
            {"who": "chip", "line": "The General is rebuilding the Tan radar network from Station Vanilla. When asked why they named it Vanilla, a Tan spokesman said, quote, 'It felt on brand.'", "gesture": "Yes"},
            {"who": "gary", "line": "Chip, I'm live on the polar shelf. It is so cold out here my microphone has frozen to my hand. I'm going to be holding it forever now. This is my life.", "headline": "LIVE: POLAR SHELF"},
            {"who": "gary", "line": "Command has issued our soldier a warm coat. It's painted on. Same as last time."},
            {"who": "brenda", "line": "Destroy three radar dishes and get out before the blizzard. Should be easy, said someone who is staying indoors.", "gesture": "No"},
        ],
    },
    {   # 4 Green Hell
        "theme": "jungle",
        "ticker": [
            "MOSQUITOES SAY THEY ARE 'FINALLY GETTING SOME RESPECT'",
            "ANCIENT TEMPLE RATED 2 STARS: 'TOO MANY STAIRS'",
            "RIVER LEVELS: WET",
            "PNN REMINDS VIEWERS: BAMBOO IS A GRASS. THINK ABOUT IT",
        ],
        "beats": [
            {"who": "chip", "line": "Data from the Vanilla radar dishes has revealed a Tan prison camp deep in the Rio Verde jungle.", "headline": "GREEN POWS FOUND IN JUNGLE"},
            {"who": "brenda", "line": "Four green soldiers captured at the kitchen table are being held in bamboo cages around an ancient temple. Their families have been told they are 'on a long camping trip.'", "headline": "POWS 'ON CAMPING TRIP,' SAYS COMMAND"},
            {"who": "gary", "line": "Chip, I'm in the jungle, and it is humid. I don't mean a little humid. My clipboard is now soup.", "headline": "LIVE: RIO VERDE JUNGLE"},
            {"who": "gary", "line": "Locals say the temple was built thousands of years ago by the Lost Civilization of the Lid. We don't know what they were the lid of. Nobody does.", "gesture": "No"},
            {"who": "chip", "line": "Our soldier's mission: free every prisoner and get them to the helipad. Nobody gets left in a cage, Brenda.", "gesture": "Yes"},
            {"who": "brenda", "line": "Unless it's a meeting cage, Chip. Then you can leave them in there.", "headline": "BRENDA: 'SOME MEETINGS SHOULD BE CAGES'"},
        ],
    },
    {   # 5 Bath Time
        "theme": "bath",
        "ticker": [
            "RUBBER DUCK DECLINES TO COMMENT; SQUEAKS INSTEAD",
            "SHAMPOO BOTTLE 'LATHER, RINSE, REPEAT' INSTRUCTIONS CALLED 'A TRAP'",
            "TOILET FLUSHED; 4 TAN SAILORS STILL MISSING",
            "BATH MAT ELECTED MAYOR OF THE FLOOR",
        ],
        "beats": [
            {"who": "chip", "line": "Breaking news from upstairs. The rescued prisoners overheard Tan plans to launch a navy from the bathtub.", "headline": "TAN NAVY SPOTTED IN BATHTUB"},
            {"who": "brenda", "line": "The fleet is commanded by Admiral Ecru, who has never been to sea but has been in the bath many times.", "headline": "ADMIRAL ECRU: 'THE TUB IS MY OCEAN'"},
            {"who": "chip", "line": "The Tan fleet is fuelled from three shampoo bottles. Experts say it is the cleanest navy in history.", "gesture": "Yes"},
            {"who": "gary", "line": "Chip, I'm live by the tub, standing next to a rubber duck the size of a house. It is looking at me. I don't know what it wants.", "headline": "LIVE: THE PORCELAIN SEA"},
            {"who": "gary", "line": "The floor tiles are very slippery and I'd like to say to everyone at home: always use a bath mat. This has been a public service announcement."},
            {"who": "brenda", "line": "The mission: blow up the fuel and sink the Admiral. Also, someone please hang up a towel. It's a mess in here.", "gesture": "No"},
        ],
    },
    {   # 6 Beachhead
        "theme": "beach",
        "ticker": [
            "SEAGULLS DEMAND CHIPS; CHIP PLASTERSON DECLINES",
            "SANDCASTLE BUILDING PERMITS SUSPENDED",
            "SUNSCREEN SHORTAGE: TOY SOLDIERS 'TECHNICALLY FINE'",
            "TIDE GOES OUT, COMES BACK; EXPERTS BAFFLED",
        ],
        "beats": [
            {"who": "chip", "line": "With the Tan Navy washed up, Command has ordered a full landing on the Crumb Coast.", "headline": "GREEN ARMY LANDS ON CRUMB COAST"},
            {"who": "brenda", "line": "Waiting for them: Major Fawn and four concrete bunkers dug into the dunes. The Major says he loves the beach, but only from behind thick concrete.", "headline": "MAJOR FAWN: 'I'M A BUNKER PERSON'"},
            {"who": "gary", "line": "Chip, I'm on the beach, and I want to be clear: this is not a vacation. I have been told that many times by my boss. Who is on vacation.", "headline": "LIVE: LANDING ZONE SAND DOLLAR"},
            {"who": "gary", "line": "Tanks are rolling off the landing craft. One of them has a little umbrella on it. I respect that."},
            {"who": "chip", "line": "Knock out the bunkers, push into the village, and take out the Major. And please, no sand in the tanks. They're rentals.", "gesture": "Yes"},
        ],
    },
    {   # 7 Sandbox
        "theme": "yard",
        "ticker": [
            "GARDEN GNOME REFUSES TO CONFIRM OR DENY ANYTHING",
            "DOGHOUSE TENANT 'HAS NO IDEA WHAT IS GOING ON,' WAGS TAIL",
            "SPRINKLER SCHEDULE LEAKED; LAWN OUTRAGED",
            "BACKYARD HOA ISSUES 14 WARNINGS ABOUT THE WAR",
        ],
        "beats": [
            {"who": "chip", "line": "Major Fawn's survivors have retreated to the backyard, where they've built a sand-castle fortress in the sandbox.", "headline": "TAN ARMY BUILDS SAND CASTLE"},
            {"who": "brenda", "line": "Inside the castle: secret battle plans for something called 'Operation Beige Dawn.' We don't know what it is yet, but the name alone makes me sleepy.", "headline": "WHAT IS 'BEIGE DAWN'?"},
            {"who": "gary", "line": "Chip, I'm in the backyard next to a garden gnome. I asked him whose side he's on, and he just kept smiling. It's the smiling that worries me.", "headline": "LIVE: THE BACKYARD"},
            {"who": "gary", "line": "Also, there's a garden hose here the size of a train. Nobody has turned it on. Nobody. Touch. The tap."},
            {"who": "chip", "line": "Recover all three pieces of the plans, then head to the doghouse for pick-up. The dog has agreed to look the other way.", "gesture": "Yes"},
        ],
    },
    {   # 8 Night Shift
        "theme": "port",
        "ticker": [
            "PORT OCHRE NIGHT SHIFT UNION: 'WE DIDN'T SIGN UP FOR TANKS'",
            "SHIPPING CONTAINER STACKED ON WRONG CONTAINER; NOBODY SURPRISED",
            "FLOODLIGHT BULBS: STILL THE OLD KIND",
            "CRANE OPERATOR WAVES AT PNN; IS ACTUALLY A SNIPER",
        ],
        "beats": [
            {"who": "chip", "line": "Good evening. Very late evening. The Beige Dawn plans show the Tan Army shipping in fuel through Port Ochre tonight.", "headline": "TAN FUEL ARRIVING AT PORT OCHRE"},
            {"who": "brenda", "line": "That fuel will power General Beige's big plan. We still don't know what that plan is, but it requires a lot of fuel and, apparently, beige paint.", "headline": "BEIGE PAINT ORDERS UP 9,000%"},
            {"who": "gary", "line": "Chip, it's dark out here. Really dark. I've been doing this report to a forklift for ten minutes. I thought it was you.", "headline": "LIVE: CONTAINER TERMINAL 9"},
            {"who": "gary", "line": "The containers are stacked two high and the snipers are on the cranes. Command says stay out of the floodlights. And please, no flash photography."},
            {"who": "chip", "line": "Blow the fuel depots, get out the south-west gate. And try to be home by morning. Some of us have early shifts.", "gesture": "No"},
        ],
    },
    {   # 9 Bunk Bed
        "theme": "bedroom",
        "ticker": [
            "MONSTER UNDER THE BED: 'IT'S GETTING CROWDED DOWN HERE'",
            "BEDTIME POSTPONED FOR STRATEGIC REASONS",
            "LEGO BRICK STEPPED ON; ENTIRE HOUSE HEARS ABOUT IT",
            "NIGHT LIGHT WORKING OVERTIME; ASKS FOR RAISE",
        ],
        "beats": [
            {"who": "chip", "line": "General Beige has had enough. His forces are massing under the bunk bed for an attack on the toy fort - the Green Army's last base in the house.", "headline": "TAN ARMY MASSES UNDER BUNK BED"},
            {"who": "brenda", "line": "Sources say the monster that usually lives under the bed has moved out. He said the Tan Army 'never cleans up' and 'talks during movies.'", "headline": "MONSTER MOVES OUT, CITES 'BAD ROOMMATES'"},
            {"who": "gary", "line": "Chip, I'm live on the rug next to the fort. I've stepped on two Lego bricks so far. I would like to file a complaint with every Lego brick.", "headline": "LIVE: FORT BLANKET"},
            {"who": "gary", "line": "The plan is to hold the fort until bedtime. Bedtime is in seventy-five seconds. That's the earliest bedtime I've ever heard of, but I'm not complaining."},
            {"who": "chip", "line": "Get to the fort, hold it, then clear the room. And grab the machine gun. Command says you'll want it. Command is rarely right, but this time, probably.", "gesture": "Yes"},
        ],
    },
    {   # 10 Mountain Pass
        "theme": "mountain",
        "ticker": [
            "SKI LODGE HOT TUB CLOSED 'FOR MILITARY REASONS'",
            "BISCUIT PASS RENAMED 'COOKIE PASS' BY POPULAR VOTE; VOTE IGNORED",
            "AVALANCHE RISK: MEDIUM. VIBES: TENSE",
            "YETI SIGHTING DISMISSED AS 'JUST GARY IN A COAT'",
        ],
        "beats": [
            {"who": "chip", "line": "Tonight, the mountains. General Beige's supplies all come through one road: Biscuit Pass.", "headline": "BISCUIT PASS: BEIGE'S LIFELINE"},
            {"who": "brenda", "line": "The pass is guarded by two missile sites and Brigadier Biscuit, who runs everything from a ski lodge at the top. He's never skied. He just likes the hot tub.", "headline": "BRIGADIER BISCUIT 'NOT A SKIER'"},
            {"who": "gary", "line": "Chip, I'm at the bottom of the canyon. Snipers on every rock pillar. I'm wearing three coats. Two of them are mine.", "headline": "LIVE: BISCUIT PASS"},
            {"who": "gary", "line": "There's a bridge over a frozen river halfway up. It's very pretty. Please don't blow it up. I parked on it."},
            {"who": "chip", "line": "Destroy both missile sites and take out the Brigadier. Then Command says we are 'very, very close' to General Beige.", "gesture": "Yes"},
            {"who": "brenda", "line": "Command said that last week too, Chip.", "gesture": "No"},
        ],
    },
    {   # 11 Garage Sale
        "theme": "garage",
        "ticker": [
            "EVERYTHING MUST GO, INCLUDING THE TAN ARMY",
            "BOX LABELLED 'MISC' FOUND TO CONTAIN MORE BOXES LABELLED 'MISC'",
            "BICYCLE LAST RIDDEN IN 2009 STILL 'WORTH A LOT,' SAYS DAD",
            "GAS CAN PRICES: EXPLOSIVE",
        ],
        "beats": [
            {"who": "chip", "line": "The last Tan convoy from the mountains has rolled into the garage, right in the middle of a garage sale.", "headline": "TAN ARMY HIDES IN GARAGE SALE"},
            {"who": "brenda", "line": "They've hidden fuel in gas cans among the junk. Shoppers report that the Tan soldiers are 'not for sale' and 'quite rude about it.'", "headline": "SHOPPERS: TAN SOLDIERS 'NOT FOR SALE'"},
            {"who": "gary", "line": "Chip, I'm in the garage next to a car the size of a mountain. A woman just offered me a quarter for my microphone. I said no. Then I said maybe.", "headline": "LIVE: THE GARAGE"},
            {"who": "gary", "line": "Somewhere in here is a map to General Beige's headquarters. Somewhere. In a garage. Chip, this could take years."},
            {"who": "chip", "line": "Blow up the fuel, find all three pieces of the map. Check the workbench and the shelves. It's always on the shelves.", "gesture": "Yes"},
        ],
    },
    {   # 12 Beige Dawn
        "theme": "couch",
        "ticker": [
            "LIVING ROOM DECLARED 'THE BIG ONE, FOR REAL THIS TIME'",
            "REMOTE CONTROL MISSING; FOUND IN COUCH; COUCH IS NOW A FORTRESS",
            "PAINT STORE SOLD OUT OF EVERY COLOUR EXCEPT BEIGE",
            "PNN ANCHORS ASK VIEWERS TO 'PLEASE STAY TUNED, WE'RE SCARED'",
        ],
        "beats": [
            {"who": "both", "line": "This is a PNN special report.", "headline": "SPECIAL REPORT: BEIGE DAWN"},
            {"who": "chip", "line": "The map from the garage led us here: the living room. General Beige has turned the couch into a fortress.", "headline": "GENERAL BEIGE FOUND - IN THE COUCH"},
            {"who": "brenda", "line": "And we finally know what Beige Dawn is. The General plans to paint the entire house beige. Every wall. Every toy. Every crayon in the box.", "headline": "BEIGE DAWN: PAINT EVERYTHING BEIGE"},
            {"who": "chip", "line": "Every crayon, Brenda?", "gesture": "No"},
            {"who": "brenda", "line": "The red one. The blue one. Even the one that's called 'Electric Lime.'", "headline": "CRAYON COMMUNITY IN SHOCK"},
            {"who": "gary", "line": "Chip, I'm on the rug. He's broadcasting the plan through three TV antennas. Right now every TV in the house is showing a slideshow about beige. It's very long.", "headline": "LIVE: THE LIVING ROOM"},
            {"who": "chip", "line": "Destroy the antennas, climb the cushions, defeat General Beige, and get out by the window. Soldier... the whole house is counting on you.", "gesture": "Yes"},
        ],
    },
]

const MORE_OUTROS := [
    {   # 3
        "theme": "snow",
        "ticker": ["RADAR DISHES NOW 'MODERN ART'", "PENGUIN SPOKESMAN: 'STILL NOT INVOLVED'", "GARY'S HAND STILL STUCK TO MICROPHONE"],
        "beats": [
            {"who": "chip", "line": "All three radar dishes at Station Vanilla are down!", "headline": "STATION VANILLA OFF THE AIR", "gesture": "Wave"},
            {"who": "brenda", "line": "And the data from those dishes has revealed something else: a Tan prison camp, deep in the jungle. With our boys inside.", "headline": "NEXT: JUNGLE PRISON CAMP"},
            "STATS",
            {"who": "gary", "line": "Chip, the helicopter's here. They say they'll thaw my hand out on the way. It'll take about six hours. I'll keep reporting.", "headline": "LIVE: THE EAST RIDGE"},
        ],
    },
    {   # 4
        "theme": "jungle",
        "ticker": ["POWS RETURN HOME; FAMILIES ASK 'HOW WAS CAMPING?'", "TEMPLE OF THE LID STILL A MYSTERY", "MOSQUITOES THROW FAREWELL PARTY"],
        "beats": [
            {"who": "chip", "line": "Every prisoner is free! Four green soldiers are coming home.", "headline": "ALL POWS RESCUED!", "gesture": "Wave"},
            {"who": "brenda", "line": "In their debrief, the POWs said the guards kept talking about 'the bathtub' and 'Admiral Ecru.' One POW said they talked about it 'way too much.'", "headline": "POWS: TAN NAVY IN THE BATHTUB?"},
            "STATS",
            {"who": "gary", "line": "Chip, the POWs said the worst part of being captured wasn't the cage. It was the food. Everything was beige.", "headline": "LIVE: THE HELIPAD"},
        ],
    },
    {   # 5
        "theme": "bath",
        "ticker": ["ADMIRAL ECRU SINKS; NAVY 'IN THE DRAIN'", "RUBBER DUCK GIVEN MEDAL; SQUEAKS PROUDLY", "BATHROOM NOW SMELLS 'LIKE A MANGO EXPLODED'"],
        "beats": [
            {"who": "chip", "line": "Admiral Ecru has been sunk, and the Tan Navy is finished!", "headline": "TAN NAVY SUNK!", "gesture": "Wave"},
            {"who": "brenda", "line": "The fuel depots exploded in a cloud of mango-coconut shampoo. The bathroom now smells amazing. Military experts call it 'a fragrant victory.'", "headline": "BATHROOM 'SMELLS GREAT,' SAY TROOPS"},
            "STATS",
            {"who": "chip", "line": "With the navy gone, Command is ordering a beach landing. Gary, pack your swimsuit.", "gesture": "Yes"},
            {"who": "gary", "line": "Chip, I don't own a swimsuit. I own this suit. It's the only suit.", "headline": "LIVE: THE PORCELAIN SEA"},
        ],
    },
    {   # 6
        "theme": "beach",
        "ticker": ["CRUMB COAST LIBERATED; SEAGULLS CLAIM CREDIT", "BUNKERS FOR SALE: 'NEEDS WORK'", "MAJOR FAWN'S SUNGLASSES FOUND, KEPT BY GARY"],
        "beats": [
            {"who": "chip", "line": "The beach is ours! Every bunker is rubble and Major Fawn has melted on the sand.", "headline": "BEACHHEAD SECURED!", "gesture": "Wave"},
            {"who": "brenda", "line": "His last words were reportedly: 'Tell General Beige... the backyard... the sandbox...' Then he melted. It was very dramatic.", "headline": "FAWN'S LAST WORDS: 'THE SANDBOX'"},
            "STATS",
            {"who": "gary", "line": "Chip, I found the Major's sunglasses. I'm keeping them. For journalism.", "headline": "LIVE: CRUMB COAST"},
        ],
    },
    {   # 7
        "theme": "yard",
        "ticker": ["SAND CASTLE CONDEMNED BY CITY INSPECTORS", "GARDEN GNOME STILL SMILING; INVESTIGATION ONGOING", "DOG GETS TREAT FOR 'BEING A GOOD BOY ABOUT ALL THIS'"],
        "beats": [
            {"who": "chip", "line": "We have the plans! All three pieces of the Beige Dawn intel are in Green hands.", "headline": "BEIGE DAWN PLANS CAPTURED!", "gesture": "Wave"},
            {"who": "brenda", "line": "Analysts are still decoding them. So far we know Beige Dawn needs a lot of fuel. Coming in by ship. Tonight. To Port Ochre.", "headline": "NEXT: PORT OCHRE"},
            "STATS",
            {"who": "gary", "line": "Chip, the dog has been a very good boy through all of this, and I think he deserves a mention on the news. Good boy, Biscuit. Wait - Biscuit? Hmm.", "headline": "LIVE: THE DOGHOUSE"},
        ],
    },
    {   # 8
        "theme": "port",
        "ticker": ["PORT OCHRE FIRE VISIBLE FROM SPACE, SAYS ONE GUY", "NIGHT SHIFT UNION DEMANDS HAZARD PAY, GETS IT", "FORKLIFT NAMED EMPLOYEE OF THE MONTH"],
        "beats": [
            {"who": "chip", "line": "The fuel depots at Port Ochre went up in a very big, very orange fireball.", "headline": "PORT OCHRE FUEL DESTROYED!", "gesture": "Wave"},
            {"who": "brenda", "line": "General Beige is said to be 'extremely annoyed.' He's gathering everything he has left under a bunk bed for one last push.", "headline": "BEIGE 'EXTREMELY ANNOYED'"},
            "STATS",
            {"who": "gary", "line": "Chip, the forklift and I have become close friends tonight. I'm going to miss him. His name is Steve.", "headline": "LIVE: CONTAINER TERMINAL 9"},
        ],
    },
    {   # 9
        "theme": "bedroom",
        "ticker": ["FORT BLANKET HOLDS!", "MONSTER MOVES BACK IN UNDER BED, 'MUCH CLEANER NOW'", "LEGO BRICK STILL ON FLOOR; STILL A MENACE"],
        "beats": [
            {"who": "chip", "line": "The fort held! Bedtime came and the Green flag is still flying over the rug.", "headline": "THE FORT HOLDS!", "gesture": "Wave"},
            {"who": "brenda", "line": "Captured Tan officers say General Beige's supplies all come through one mountain road: Biscuit Pass.", "headline": "NEXT: BISCUIT PASS"},
            "STATS",
            {"who": "gary", "line": "Chip, I'd like to report that the monster under the bed has moved back in. He brought a cake. Nice guy, actually.", "headline": "LIVE: FORT BLANKET"},
        ],
    },
    {   # 10
        "theme": "mountain",
        "ticker": ["BISCUIT PASS REOPENS; FIRST CAR IS GARY'S", "SKI LODGE HOT TUB REOPENS TO THE PUBLIC", "YETI SPOTTED AGAIN; IT WAS GARY AGAIN"],
        "beats": [
            {"who": "chip", "line": "Brigadier Biscuit has been melted in his own ski lodge, and both missile sites are down.", "headline": "BISCUIT PASS CLEARED!", "gesture": "Wave"},
            {"who": "brenda", "line": "The last Tan convoy got away and was tracked to - and I'm reading this right - a garage sale.", "headline": "TAN CONVOY FLEES TO GARAGE SALE"},
            "STATS",
            {"who": "gary", "line": "Chip, good news - the bridge survived, and so did my car. Bad news - I locked my keys in it.", "headline": "LIVE: BISCUIT PASS"},
        ],
    },
    {   # 11
        "theme": "garage",
        "ticker": ["GARAGE SALE ENDS; NOTHING SOLD EXCEPT GARY'S MICROPHONE", "DAD STILL WON'T SELL THE BICYCLE", "MAP TO BEIGE HQ FOUND ON SHELF; OF COURSE IT WAS"],
        "beats": [
            {"who": "chip", "line": "We have the map! All three pieces were found in the garage. And yes, one was on the shelf.", "headline": "MAP TO BEIGE HQ FOUND!", "gesture": "Wave"},
            {"who": "brenda", "line": "The map leads to one place. The living room. The couch. General Beige has been in the couch this whole time.", "headline": "NEXT: THE LIVING ROOM"},
            "STATS",
            {"who": "chip", "line": "This is it, folks. The final battle. Get some sleep tonight. Our soldier won't.", "gesture": "Yes"},
            {"who": "gary", "line": "Chip, I sold my microphone for a quarter. I'm talking into a banana now. Nobody has noticed.", "headline": "LIVE: THE GARAGE"},
        ],
    },
    {   # 12 - the finale
        "theme": "couch",
        "ticker": ["GENERAL BEIGE DEFEATED; HOUSE KEEPS ALL ITS COLOURS", "ELECTRIC LIME CRAYON SAFE AND WELL", "THANK YOU FOR WATCHING PNN. PLEASE PUT YOUR TOYS AWAY"],
        "beats": [
            {"who": "both", "line": "This is a PNN special report.", "headline": "SPECIAL REPORT: VICTORY"},
            {"who": "chip", "line": "General Beige has been defeated! The couch fortress has fallen and Beige Dawn is cancelled!", "headline": "GENERAL BEIGE DEFEATED!", "gesture": "Wave"},
            {"who": "brenda", "line": "Every wall, every toy, and every crayon in the house keeps its colour. The red one. The blue one. And yes, Electric Lime.", "headline": "THE HOUSE KEEPS ITS COLOURS"},
            "STATS",
            {"who": "gary", "line": "Chip, the humans have woken up. They found tiny puddles of beige plastic all over the couch. They're blaming the cat again.", "headline": "LIVE: THE LIVING ROOM"},
            {"who": "chip", "line": "The cat's lawyer says this is, quote, 'getting ridiculous.'", "headline": "CAT'S LAWYER: 'RIDICULOUS'", "gesture": "No"},
            {"who": "brenda", "line": "From all of us at PNN: thank you to one small green soldier. Command says he'll get a medal. And a day off. Probably just the medal.", "gesture": "Yes"},
            {"who": "both", "line": "That's the news. I'm Chip Plasterson. And I'm Brenda Mold. Goodnight, and please put your toys away.", "headline": "THANKS FOR WATCHING PNN"},
        ],
    },
]
