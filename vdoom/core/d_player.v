module core

pub enum PlayerState {
	live
	dead
	reborn
}

@[_allow_multiple_values]
pub enum Cheat {
	noclip = 1
	godmode = 2
	nomomentum = 4
}

pub struct Player {
pub mut:
	mo             &Mobj = unsafe { nil }
	playerstate    PlayerState
	cmd            TicCmd
	viewz          Fixed
	viewheight     Fixed
	deltaviewheight Fixed
	bob            Fixed
	health         int
	armorpoints    int
	armortype      int
	powers         []int = []int{len: numpowers}
	cards          []bool = []bool{len: numcards}
	backpack       bool
	frags          []int = []int{len: maxplayers}
	readyweapon    WeaponType
	pendingweapon  WeaponType
	weaponowned    []int = []int{len: numweapons}
	ammo           []int = []int{len: numammo}
	maxammo        []int = []int{len: numammo}
	attackdown     int
	usedown        int
	cheats         int
	refire         int
	killcount      int
	itemcount      int
	secretcount    int
	message        string
	damagecount    int
	bonuscount     int
	attacker       &Mobj = unsafe { nil }
	extralight     int
	fixedcolormap  int
	colormap       int
	psprites       []PspDef = []PspDef{len: numpsprites}
	didsecret      bool
}

pub struct WbPlayerStruct {
pub mut:
	in_game bool
	skills  int
	sitems  int
	ssecret int
	stime   int
	frags   []int = []int{len: 4}
	score   int
}

pub struct WbStartStruct {
pub mut:
	epsd      int
	didsecret bool
	last      int
	next      int
	maxkills  int
	maxitems  int
	maxsecret int
	maxfrags  int
	partime   int
	pnum      int
	plyr      []WbPlayerStruct = []WbPlayerStruct{len: maxplayers}
}
