@[translated]
module main

// Generate a randomized, private, memorable name for a player.

fn C.rand() int
fn C.srand(u32)

@[c: 'M_StringJoin']
@[c2v_variadic]
fn m_string_join(s &i8, ...) &i8

const adjectives = [
	c'Grumpy',
	c'Ecstatic',
	c'Surly',
	c'Prepared',
	c'Crafty',
	c'Alert',
	c'Sluggish',
	c'Testy',
	c'Reluctant',
	c'Languid',
	c'Passive',
	c'Pacifist',
	c'Aggressive',
	c'Hostile',
	c'Bubbly',
	c'Giggly',
	c'Laughing',
	c'Crying',
	c'Frowning',
	c'Torpid',
	c'Lethargic',
	c'Manic',
	c'Patient',
	c'Protective',
	c'Philosophical',
	c'Enquiring',
	c'Debating',
	c'Furious',
	c'Laid-Back',
	c'Easy-Going',
	c'Cromulent',
	c'Excitable',
	c'Tired',
	c'Exhausted',
	c'Ruminating',
	c'Redundant',
	c'Sporty',
	c'Ginger',
	c'Scary',
	c'Posh',
	c'Baby',
]

const nouns = [
	c'Frad',
	c'Cacodemon',
	c'Arch-Vile',
	c'Cyberdemon',
	c'Imp',
	c'Demon',
	c'Mancubus',
	c'Arachnotron',
	c'Baron',
	c'Knight',
	c'Revenant',
	c'Ettin',
	c'Maulotaur',
	c'Centaur',
	c'Afrit',
	c'Serpent',
	c'Disciple',
	c'Gargoyle',
	c'Golem',
	c'Lich',
	c'Sentinel',
	c'Acolyte',
	c'Templar',
	c'Reaver',
	c'Spectre',
]

fn init_pet_name() {
	C.srand(u32(i_get_time_ms()))
}

@[export: 'NET_GetRandomPetName']
pub fn net_get_random_pet_name() &i8 {
	init_pet_name()
	a := adjectives[C.rand() % adjectives.len]
	n := nouns[C.rand() % nouns.len]
	return m_string_join(a, c' ', n, unsafe { nil })
}
