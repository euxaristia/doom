@[translated]
module main

// Control binding hooks: minimal manual port.

@[export: 'M_BindBaseControls']
pub fn m_bind_base_controls() {}

@[export: 'M_BindWeaponControls']
pub fn m_bind_weapon_controls() {}

@[export: 'M_BindMapControls']
pub fn m_bind_map_controls() {}

@[export: 'M_BindMenuControls']
pub fn m_bind_menu_controls() {}

@[export: 'M_BindChatControls']
pub fn m_bind_chat_controls() {}
