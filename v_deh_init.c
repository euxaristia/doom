// V dehacked init bridge for mixed C/V builds.

#ifdef __cplusplus
extern "C" {
#endif

void V_DEH_Init(void);

#ifdef __cplusplus
}
#endif

__attribute__((constructor))
static void v_deh_init_constructor(void) {
    V_DEH_Init();
}
