map_event_to_action :: (event: Input.Event, $Action: Type) -> Action {
    invalid := cast(Action) 0xFFFF;
    if event.type != .KEYBOARD return invalid;
    if !event.key_pressed return invalid;
    
    keymap := get_keymap_for_action_type(Action);

    event_key_code := cast(u32) event.key_code;
    
    for keymap {
        if it.combo.key_code == event_key_code && it.combo.mods.packed == (event.modifier_flags.packed | it.combo.ignore.packed) {
            return cast(Action) it.action;
        }
    }
    return invalid;
}

// Only reacts to non-modifier keys being released
map_key_release_event_to_actions :: (event: Input.Event, $Action: Type) -> [] Action /* temporary storage */ {
    if event.type != .KEYBOARD || event.key_pressed return .[];
    
    actions: [..] Action;
    actions.allocator = temp;
    
    keymap := get_keymap_for_action_type(Action);

    event_key_code := cast(u32) event.key_code;
    
    for keymap {
        if it.combo.key_code == event_key_code {
            array_add(*actions, cast(Action) it.action);
        }
    }
    return actions;
}


#scope_file

get_keymap_for_action_type :: ($Action: Type) -> [] Key_Mapping #expand {
    #if Action == Action_Common {
        return config.keymap.common;
    } else #if Action == Action_Editors {
        return config.keymap.editors;
    } else #if Action == Action_Open_File_Dialog {
        return config.keymap.open_file_dialog;
    } else #if Action == Action_Search_Dialog {
        return config.keymap.search_dialog;
    } else {
        #assert(false, "In map_event_to_action, the passed action type is not supported.");
    }
}

#scope_export

Key_Mapping :: struct {
    combo:  Key_Combo;
    action: u32;  // NOTE: tried to use a union with actual enums here, but the compiler crashes @compilerbug
}

Key_Combo :: struct {
    key_code: u32;
    mods: Mods;  
    ignore: Mods;
} #no_padding;

// Generate action enums from the corresponding arrays below
#insert -> string {
    b: String_Builder;
    init_string_builder(*b);

    define_enum :: (b: *String_Builder, enum_name: string, values: [] string) {
        print_to_builder(b, "% :: enum u16 {\n", enum_name);
        for v : values print_to_builder(b, "    %;\n", v);
        print_to_builder(b, "}\n");
    }

    define_enum(*b, "Action_Common",           ACTIONS_COMMON);
    define_enum(*b, "Action_Editors",          ACTIONS_EDITORS);
    define_enum(*b, "Action_Open_File_Dialog", ACTIONS_OPEN_FILE_DIALOG);
    define_enum(*b, "Action_Search_Dialog",    ACTIONS_SEARCH_DIALOG);

    return builder_to_string(*b);
}

ACTIONS_COMMON :: string.[
    "search_in_buffer",
    "search_in_project",
    "show_open_file_dialog_in_search_mode",
    "show_open_file_dialog_in_navigate_mode",
    "show_open_file_dialog_in_navigate_mode_from_root",
    "copy",
    "cut",
    "paste",
    "undo",
    "redo",
    "select_word",
    "select_all",
    "toggle_expand",
    "move_up",
    "move_up_fast",
    "move_up_one_page",
    "move_down",
    "move_down_fast",
    "move_down_one_page",
    "move_left",
    "move_left_by_word",
    "move_left_by_word_ends",
    "move_right",
    "move_right_by_word",
    "move_right_by_word_ends",
    "home",
    "end",
    "delete_left_char",
    "delete_right_char",
    "delete_word_left",
    "delete_word_right",
    "increase_font_size",
    "decrease_font_size",
    "reset_font_size_to_default",
];

ACTIONS_EDITORS :: #run arrays_concat(ACTIONS_COMMON, string.[
    "select_word_or_create_another_cursor",
    "duplicate_lines",
    "move_selected_lines_up",
    "move_selected_lines_down",
    "indent_or_go_to_next_tabstop",
    "unindent",
    "indent",
    "close_current_editor",
    "close_other_editor",
    "save",
    "toggle_comment",
    "select_line",
    "scroll_viewport_up",
    "scroll_viewport_down",
    "scroll_viewport_left",
    "scroll_viewport_right",
    "move_up_to_empty_line",
    "move_down_to_empty_line",
    "move_cursor_to_viewport_center",
    "remove_additional_cursors",
    "break_line",
    "new_line_below_without_breaking",
    "new_line_above_without_breaking",
    "switch_to_left_editor",
    "switch_to_right_editor",
    "move_editor_to_the_left",
    "move_editor_to_the_right",
]);

ACTIONS_OPEN_FILE_DIALOG :: #run arrays_concat(ACTIONS_COMMON, string.[
    "close_dialog",
    "open_entry_in_place",
    "open_entry_on_the_side",
    "open_entry_on_the_left",
    "open_entry_on_the_right",
    "open_directory",
    "pop_directory",
]);

ACTIONS_SEARCH_DIALOG :: #run arrays_concat(ACTIONS_COMMON, string.[
    "close_dialog",
    "open_entry_in_place",
    "open_entry_on_the_side",
    "open_entry_on_the_left",
    "open_entry_on_the_right",
]);

// Used for testing strings in parser
Keymap_Action_Strings :: #run -> Table(string, void) {
    table: Table(string, void);
    nothing: void;
    
    for ACTIONS_EDITORS             table_set(*table, it, nothing);
    for ACTIONS_OPEN_FILE_DIALOG    table_set(*table, it, nothing);
    for ACTIONS_SEARCH_DIALOG       table_set(*table, it, nothing);
    
    return table;
}