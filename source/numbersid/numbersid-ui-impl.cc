/*
    UI implementation for numbersid.c, this must live in a .cc file.
*/

#include "chips/chips_common.h"
#include "chips/clk.h"
#include "chips/m6581.h"

#include "imgui.h"
#include "imgui_internal.h"

#define CHIPS_UI_IMPL
#include "ui/ui_util.h"
#include "ui/ui_settings.h"
#include "ui/ui_snapshot.h"
#include "ui/ui_chip.h"
#include "ui/ui_m6581.h"
#include "ui/ui_audio.h"
#include "ui/ui_display.h"

#include "sequencer.h"
#include "ui_timecontrol.h"
#include "ui_parameters.h"
#include "ui_variables.h"
#include "ui_arrays.h"
#include "ui_preview.h"
#include "ui_help.h"
#include "ui_data.h"

#include "ui_numbersid.h"
