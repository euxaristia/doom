@[translated]
module main

fn C.M_LoadDefaults()
fn C.M_SaveDefaults()
fn C.M_SetDefaultValue(&char, voidptr)
fn C.M_GetDefaultValue(&char) voidptr
fn C.M_BindVariable(&char, voidptr)

fn m_load_defaults() { C.M_LoadDefaults() }
fn m_save_defaults() { C.M_SaveDefaults() }
fn m_set_default_value(var_name &char, value voidptr) { C.M_SetDefaultValue(var_name, value) }
fn m_get_default_value(var_name &char) voidptr { return C.M_GetDefaultValue(var_name) }
fn m_bind_variable(name &char, location voidptr) { C.M_BindVariable(name, location) }
