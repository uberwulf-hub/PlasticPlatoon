extends RefCounted
## PNN, the Plastic News Network. Parody news breaks shown before and after
## each operation. House style: silly for kids, with a dry grown-up undertone
## (budgets, Wi-Fi, family dinners, office life). Keep it clean: no swearing,
## nothing scary, no real people or real places.
##
## A script is {"theme", "ticker": [..], "beats": [{"who", "line", "headline"?, "gesture"?}]}.
## who: "chip" (anchor), "brenda" (co-anchor), "gary" (field reporter), "both" (wide shot).
## {kills}, {total}, {time}, {headshots}, {accuracy} are filled in from mission stats.

const THEMES := ["desert", "city", "table"]


static func intro(op: int) -> Dictionary:
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
        _:
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


static func outro(op: int, success: bool, stats: Dictionary) -> Dictionary:
    var d: Dictionary
    if not success:
        d = _fail(op)
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
                        {"who": "both", "line": "That's the news. I'm Chip Plasterson. And I'm Brenda Mold. Goodnight, and please don't leave your toys on the table.", "headline": "THANKS FOR WATCHING PNN"},
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
    var place: String = ["the desert", "Port Varos", "the kitchen table"][clampi(op, 0, 2)]
    return {
        "theme": THEMES[clampi(op, 0, 2)],
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
