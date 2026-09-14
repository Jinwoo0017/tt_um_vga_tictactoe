`default_nettype none

module tt_um_vga_tictactoe (
    input wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input wire ena,
    input wire clk,
    input wire rst_n
);

    wire hsync;
    wire vsync;
    wire display_on;
    wire [9:0] hpos;
    wire [9:0] vpos;

    hvsync_generator hvsync_gen (
        .clk        (clk),
        .reset      (!rst_n),
        .hsync      (hsync),
        .vsync      (vsync),
        .display_on (display_on),
        .hpos       (hpos),
        .vpos       (vpos)
    );

    assign uio_out = 8'b0;
    assign uio_oe  = 8'b0;

    /*
     * CONTROLS
     *
     * ui_in[1] = UP
     * ui_in[2] = DOWN
     * ui_in[3] = LEFT
     * ui_in[4] = RIGHT
     * ui_in[5] = ATTACK  (place mark on selected cell)
     * ui_in[7] = NEW GAME
     */

    wire key_up     = ui_in[1];
    wire key_down   = ui_in[2];
    wire key_left   = ui_in[3];
    wire key_right  = ui_in[4];
    wire key_attack = ui_in[5];
    wire key_reset  = ui_in[7]; // NEW GAME

    reg prev_up;
    reg prev_down;
    reg prev_left;
    reg prev_right;
    reg prev_attack;
    reg prev_reset;

    wire up_press     = key_up     ^ prev_up;
    wire down_press   = key_down   ^ prev_down;
    wire left_press   = key_left   ^ prev_left;
    wire right_press  = key_right  ^ prev_right;
    wire attack_press = key_attack ^ prev_attack;
    wire reset_press  = key_reset  ^ prev_reset;

    /*
     * BOARD STATE
     *
     * Two 9-bit masks, one per player. Bit i corresponds to cell
     * i (row*3 + col). A cell is empty when neither mask has
     * that bit set.
     */

    reg [1:0] cursor_row;
    reg [1:0] cursor_col;

    reg [8:0] x_mask;
    reg [8:0] o_mask;

    reg current_player;   // 0 = X, 1 = O
    reg winner;            // valid only while game_state == S_WON

    /*
     * Which of the 8 lines won - NOT which 9 cells. Row/col/diag
     * membership and border shape are both cheap to derive from
     * a single 3-bit line index, so there is no need to keep a
     * full 9-bit cell mask around just for rendering.
     */

    reg [2:0] win_line_index;

    localparam S_PLAYING = 2'd0;
    localparam S_WON     = 2'd1;
    localparam S_DRAW    = 2'd2;

    reg [1:0] game_state;

    /*
     * ROW OFFSET
     *
     * Cheap 3x3 index helper: row*3 without a multiplier.
     */

    function [3:0] row_off;
        input [1:0] r;
        begin
            case (r)
                2'd0: row_off = 4'd0;
                2'd1: row_off = 4'd3;
                default: row_off = 4'd6;
            endcase
        end
    endfunction

    wire [3:0] cursor_pos = row_off(cursor_row) + cursor_col;
    wire [8:0] cell_bit   = 9'b1 << cursor_pos;

    wire cell_empty = !(x_mask[cursor_pos] | o_mask[cursor_pos]);

    wire place_now =
        attack_press &&
        (game_state == S_PLAYING) &&
        cell_empty;

    wire [8:0] next_x_mask =
        x_mask | ((place_now && !current_player) ? cell_bit : 9'b0);

    wire [8:0] next_o_mask =
        o_mask | ((place_now && current_player) ? cell_bit : 9'b0);

    wire [8:0] current_next_mask =
        current_player ? next_o_mask : next_x_mask;

    wire board_full_next =
        (next_x_mask | next_o_mask) == 9'b111111111;

    /*
     * WIN LINES
     *
     * Same "scan and take the first match" idea as the K-map
     * solver's uncovered-cell scan, just over 8 fixed patterns
     * instead of 81 candidates. This part still needs the full
     * 9-bit patterns, because actually detecting a win requires
     * checking real board coverage - the simplification below
     * only applies to how the winning line gets DRAWN.
     */

    localparam [8:0] LINE0 = 9'b000000111; // row 0
    localparam [8:0] LINE1 = 9'b000111000; // row 1
    localparam [8:0] LINE2 = 9'b111000000; // row 2
    localparam [8:0] LINE3 = 9'b001001001; // col 0
    localparam [8:0] LINE4 = 9'b010010010; // col 1
    localparam [8:0] LINE5 = 9'b100100100; // col 2
    localparam [8:0] LINE6 = 9'b100010001; // diagonal \
    localparam [8:0] LINE7 = 9'b001010100; // diagonal /

    function [8:0] line_mask;
        input [2:0] idx;
        begin
            case (idx)
                3'd0: line_mask = LINE0;
                3'd1: line_mask = LINE1;
                3'd2: line_mask = LINE2;
                3'd3: line_mask = LINE3;
                3'd4: line_mask = LINE4;
                3'd5: line_mask = LINE5;
                3'd6: line_mask = LINE6;
                default: line_mask = LINE7;
            endcase
        end
    endfunction

    reg win_found;
    reg [2:0] matched_line_index;
    reg [8:0] test_line;
    integer li;

    always @(*) begin

        win_found = 1'b0;
        matched_line_index = 3'd0;

        for (li = 0; li < 8; li = li + 1) begin

            test_line = line_mask(li[2:0]);

            if (!win_found &&
                ((current_next_mask & test_line) == test_line)) begin

                win_found = 1'b1;
                matched_line_index = li[2:0];

            end
        end
    end

    /*
     * MAIN GAME LOGIC
     */

    always @(posedge clk) begin

        if (!rst_n) begin

            cursor_row <= 2'd0;
            cursor_col <= 2'd0;

            x_mask <= 9'b0;
            o_mask <= 9'b0;

            current_player <= 1'b0;
            winner <= 1'b0;

            win_line_index <= 3'd0;

            game_state <= S_PLAYING;

            prev_up     <= 1'b0;
            prev_down   <= 1'b0;
            prev_left   <= 1'b0;
            prev_right  <= 1'b0;
            prev_attack <= 1'b0;
            prev_reset  <= 1'b0;

        end

        else begin

            prev_up     <= key_up;
            prev_down   <= key_down;
            prev_left   <= key_left;
            prev_right  <= key_right;
            prev_attack <= key_attack;
            prev_reset  <= key_reset;

            if (reset_press) begin

                cursor_row <= 2'd0;
                cursor_col <= 2'd0;

                x_mask <= 9'b0;
                o_mask <= 9'b0;

                current_player <= 1'b0;
                winner <= 1'b0;

                win_line_index <= 3'd0;

                game_state <= S_PLAYING;

            end

            /*
             * Movement and placing are only live while the game
             * is still being played - the board freezes once
             * someone wins or it fills up, same idea as the
             * K-map file freezing the cursor once simplify_mode
             * kicked in.
             */

            else if (game_state == S_PLAYING) begin

                if (up_press) begin

                    if (cursor_row == 2'd0)
                        cursor_row <= 2'd2;
                    else
                        cursor_row <= cursor_row - 2'd1;

                end

                if (down_press) begin

                    if (cursor_row == 2'd2)
                        cursor_row <= 2'd0;
                    else
                        cursor_row <= cursor_row + 2'd1;

                end

                if (left_press) begin

                    if (cursor_col == 2'd0)
                        cursor_col <= 2'd2;
                    else
                        cursor_col <= cursor_col - 2'd1;

                end

                if (right_press) begin

                    if (cursor_col == 2'd2)
                        cursor_col <= 2'd0;
                    else
                        cursor_col <= cursor_col + 2'd1;

                end

                if (place_now) begin

                    if (!current_player)
                        x_mask <= next_x_mask;
                    else
                        o_mask <= next_o_mask;

                    if (win_found) begin

                        game_state <= S_WON;
                        winner <= current_player;
                        win_line_index <= matched_line_index;

                    end

                    else if (board_full_next) begin

                        game_state <= S_DRAW;

                    end

                    else begin

                        current_player <= ~current_player;

                    end
                end
            end
        end
    end

    /*
     * GRID GEOMETRY (3x3)
     */

    localparam GRID_X = 185;
    localparam GRID_Y = 115;

    localparam TILE_W = 90;
    localparam TILE_H = 90;

    localparam GRID_W = 270;
    localparam GRID_H = 270;

    localparam BORDER = 4;

    wire inside_grid =
        (hpos >= GRID_X) &&
        (hpos < GRID_X + GRID_W) &&
        (vpos >= GRID_Y) &&
        (vpos < GRID_Y + GRID_H);

    wire [9:0] rel_x = hpos - GRID_X;
    wire [9:0] rel_y = vpos - GRID_Y;

    wire [1:0] tile_col =
        (rel_x < 10'd90)  ? 2'd0 :
        (rel_x < 10'd180) ? 2'd1 :
                            2'd2;

    wire [1:0] tile_row =
        (rel_y < 10'd90)  ? 2'd0 :
        (rel_y < 10'd180) ? 2'd1 :
                            2'd2;

    wire [9:0] tile_x =
        (tile_col == 2'd0) ? rel_x :
        (tile_col == 2'd1) ? rel_x - 10'd90 :
                             rel_x - 10'd180;

    wire [9:0] tile_y =
        (tile_row == 2'd0) ? rel_y :
        (tile_row == 2'd1) ? rel_y - 10'd90 :
                             rel_y - 10'd180;

    wire [3:0] display_pos = row_off(tile_row) + tile_col;

    wire display_has_x = x_mask[display_pos];
    wire display_has_o = o_mask[display_pos];

    wire selected_tile =
        (tile_row == cursor_row) &&
        (tile_col == cursor_col);

    /*
     * MARK RENDERING (big X / O glyph inside the tile)
     *
     * Reuses the same font_row glyph table as the text below,
     * just rendered at a much larger scale (8px per font pixel
     * instead of 2px) so it fills most of a 90x90 tile.
     */

    localparam SYM_MARGIN_X = 25; // (90 - 5*8) / 2
    localparam SYM_MARGIN_Y = 17; // (90 - 7*8) / 2

    wire in_sym_x =
        (tile_x >= SYM_MARGIN_X) &&
        (tile_x < SYM_MARGIN_X + 40);

    wire in_sym_y =
        (tile_y >= SYM_MARGIN_Y) &&
        (tile_y < SYM_MARGIN_Y + 56);

    wire [3:0] sym_col = (tile_x - SYM_MARGIN_X) >> 3;
    wire [3:0] sym_row = (tile_y - SYM_MARGIN_Y) >> 3;

    wire [7:0] sym_char = display_has_x ? "X" : "O";

    /*
     * TILE EDGE GEOMETRY
     *
     * Shared by the grid lines, the cursor selector, and the
     * win-line border below.
     */

    wire edge_top    = tile_y < BORDER;
    wire edge_bottom = tile_y >= TILE_H - BORDER;
    wire edge_left   = tile_x < BORDER;
    wire edge_right  = tile_x >= TILE_W - BORDER;

    wire edge_active =
        edge_top | edge_bottom | edge_left | edge_right;

    wire boundary_top    = (tile_row == 2'd0);
    wire boundary_bottom = (tile_row == 2'd2);
    wire boundary_left   = (tile_col == 2'd0);
    wire boundary_right  = (tile_col == 2'd2);

    /*
     * ALWAYS-VISIBLE BOARD GRID
     *
     * Every cell's own border is drawn all the time, which is
     * what actually makes the 3x3 board visible - previously
     * only the cursor box and the win box were drawn, so an
     * unselected, unwon board rendered as blank space.
     */

    wire normal_grid = edge_active;

    /*
     * WIN-LINE BORDER
     *
     * Only 8 possible winning lines exist, and they fall into
     * 3 shapes:
     *
     *   ROW  (index 0-2): highlight top+bottom of every cell in
     *        the row, and only the outer left/right ends.
     *
     *   COL  (index 3-5): mirror of the above.
     *
     *   DIAG (index 6-7): the three cells only ever touch at a
     *        corner, never share an edge, so there is no
     *        "neighbor" to check - every edge of every cell in
     *        the diagonal gets highlighted.
     *
     * This replaces a generic per-pixel neighbor lookup (which
     * needed a computed row/col, a boundary check, and an
     * indexed read into a 9-bit mask) with a handful of direct
     * comparisons against the single stored line index.
     */

    wire is_row_win = (win_line_index <= 3'd2);
    wire is_col_win = (win_line_index >= 3'd3) && (win_line_index <= 3'd5);

    wire [2:0] rc_sum = {1'b0, tile_row} + {1'b0, tile_col};

    wire cell_in_win =
        is_row_win ? (tile_row == win_line_index[1:0]) :
        is_col_win ? (tile_col == (win_line_index - 3'd3)) :
        (win_line_index == 3'd6) ? (tile_row == tile_col) :
                                   (rc_sum == 3'd2);

    wire win_border =
        (game_state == S_WON) &&
        cell_in_win &&
        ( is_row_win ? (edge_top || edge_bottom ||
                        (boundary_left && edge_left) ||
                        (boundary_right && edge_right)) :
          is_col_win ? (edge_left || edge_right ||
                        (boundary_top && edge_top) ||
                        (boundary_bottom && edge_bottom)) :
                       edge_active );

    /*
     * RED SELECTOR (cursor)
     */

    wire selected_border =
        (game_state == S_PLAYING) &&
        selected_tile &&
        edge_active;

    /*
     * TEXT SYSTEM
     *
     * Same character-cell approach as the example file's font
     * renderer, trimmed down to only the glyphs this game
     * actually uses: A C D E F G H I K L N O P R S T U W X,
     * digits 1 2 3 4 5 7, and [ ].
     */

    localparam TEXT_CHAR_W = 12;
    localparam TEXT_CHAR_H = 14;

    localparam LABEL_X = 272;
    localparam LABEL_Y = 50;

    localparam CTRL1_X = 140;
    localparam CTRL_Y1 = 410;

    localparam CTRL2_X = 212;
    localparam CTRL_Y2 = 430;

    wire inside_label =
        (hpos >= LABEL_X) &&
        (hpos < LABEL_X + 8 * TEXT_CHAR_W) &&
        (vpos >= LABEL_Y) &&
        (vpos < LABEL_Y + TEXT_CHAR_H);

    wire inside_ctrl_row1 =
        (hpos >= CTRL1_X) &&
        (hpos < CTRL1_X + 30 * TEXT_CHAR_W) &&
        (vpos >= CTRL_Y1) &&
        (vpos < CTRL_Y1 + TEXT_CHAR_H);

    wire inside_ctrl_row2 =
        (hpos >= CTRL2_X) &&
        (hpos < CTRL2_X + 21 * TEXT_CHAR_W) &&
        (vpos >= CTRL_Y2) &&
        (vpos < CTRL_Y2 + TEXT_CHAR_H);

    wire inside_text_any =
        inside_label | inside_ctrl_row1 | inside_ctrl_row2;

    reg [9:0] text_local_x;
    reg [9:0] text_local_y;

    always @(*) begin

        text_local_x = 10'd0;
        text_local_y = 10'd0;

        if (inside_label) begin
            text_local_x = hpos - LABEL_X;
            text_local_y = vpos - LABEL_Y;
        end
        else if (inside_ctrl_row1) begin
            text_local_x = hpos - CTRL1_X;
            text_local_y = vpos - CTRL_Y1;
        end
        else if (inside_ctrl_row2) begin
            text_local_x = hpos - CTRL2_X;
            text_local_y = vpos - CTRL_Y2;
        end
    end

    wire [5:0] char_pos = text_local_x / TEXT_CHAR_W;
    wire [3:0] font_y   = text_local_y[3:1]; // /2, TEXT_SCALE is a power of 2

    /*
     * TURN / RESULT LABEL
     *
     * "[X] TURN"  while playing
     * "[O] WINS"  once a player wins
     * "  DRAW  "  if the board fills with no winner
     */

    reg [7:0] label_char;

    always @(*) begin

        label_char = " ";

        case (game_state)

            S_PLAYING: begin
                case (char_pos)
                    6'd0: label_char = "[";
                    6'd1: label_char = current_player ? "O" : "X";
                    6'd2: label_char = "]";
                    6'd3: label_char = " ";
                    6'd4: label_char = "T";
                    6'd5: label_char = "U";
                    6'd6: label_char = "R";
                    6'd7: label_char = "N";
                    default: label_char = " ";
                endcase
            end

            S_WON: begin
                case (char_pos)
                    6'd0: label_char = "[";
                    6'd1: label_char = winner ? "O" : "X";
                    6'd2: label_char = "]";
                    6'd3: label_char = " ";
                    6'd4: label_char = "W";
                    6'd5: label_char = "I";
                    6'd6: label_char = "N";
                    6'd7: label_char = "S";
                    default: label_char = " ";
                endcase
            end

            default: begin // S_DRAW
                case (char_pos)
                    6'd2: label_char = "D";
                    6'd3: label_char = "R";
                    6'd4: label_char = "A";
                    6'd5: label_char = "W";
                    default: label_char = " ";
                endcase
            end

        endcase
    end

    /*
     * CONTROL ROWS
     *
     * Row 1: "[1]UP [2]DOWN [3]LEFT [4]RIGHT"
     * Row 2: "[5]ATTACK [7]NEW GAME"
     */

    reg [7:0] ctrl_row1_char;

    always @(*) begin

        case (char_pos)
            6'd0:  ctrl_row1_char = "[";
            6'd1:  ctrl_row1_char = "1";
            6'd2:  ctrl_row1_char = "]";
            6'd3:  ctrl_row1_char = "U";
            6'd4:  ctrl_row1_char = "P";
            6'd6:  ctrl_row1_char = "[";
            6'd7:  ctrl_row1_char = "2";
            6'd8:  ctrl_row1_char = "]";
            6'd9:  ctrl_row1_char = "D";
            6'd10: ctrl_row1_char = "O";
            6'd11: ctrl_row1_char = "W";
            6'd12: ctrl_row1_char = "N";
            6'd14: ctrl_row1_char = "[";
            6'd15: ctrl_row1_char = "3";
            6'd16: ctrl_row1_char = "]";
            6'd17: ctrl_row1_char = "L";
            6'd18: ctrl_row1_char = "E";
            6'd19: ctrl_row1_char = "F";
            6'd20: ctrl_row1_char = "T";
            6'd22: ctrl_row1_char = "[";
            6'd23: ctrl_row1_char = "4";
            6'd24: ctrl_row1_char = "]";
            6'd25: ctrl_row1_char = "R";
            6'd26: ctrl_row1_char = "I";
            6'd27: ctrl_row1_char = "G";
            6'd28: ctrl_row1_char = "H";
            6'd29: ctrl_row1_char = "T";
            default: ctrl_row1_char = " ";
        endcase
    end

    reg [7:0] ctrl_row2_char;

    always @(*) begin

        case (char_pos)
            6'd0:  ctrl_row2_char = "[";
            6'd1:  ctrl_row2_char = "5";
            6'd2:  ctrl_row2_char = "]";
            6'd3:  ctrl_row2_char = "A";
            6'd4:  ctrl_row2_char = "T";
            6'd5:  ctrl_row2_char = "T";
            6'd6:  ctrl_row2_char = "A";
            6'd7:  ctrl_row2_char = "C";
            6'd8:  ctrl_row2_char = "K";
            6'd9:  ctrl_row2_char = " ";
            6'd10: ctrl_row2_char = "[";
            6'd11: ctrl_row2_char = "7";
            6'd12: ctrl_row2_char = "]";
            6'd13: ctrl_row2_char = "N";
            6'd14: ctrl_row2_char = "E";
            6'd15: ctrl_row2_char = "W";
            6'd16: ctrl_row2_char = " ";
            6'd17: ctrl_row2_char = "G";
            6'd18: ctrl_row2_char = "A";
            6'd19: ctrl_row2_char = "M";
            6'd20: ctrl_row2_char = "E";
            default: ctrl_row2_char = " ";
        endcase
    end

    wire [7:0] active_char =
        inside_label     ? label_char :
        inside_ctrl_row1 ? ctrl_row1_char :
        inside_ctrl_row2 ? ctrl_row2_char :
                           8'h20;

    /*
     * FONT
     *
     * Trimmed to only the glyphs this design uses: A C D E F G
     * H I K L N O P R S T U W X, digits 1 2 3 4 5 7, and [ ].
     */

    function [4:0] font_row;
        input [7:0] ch;
        input [3:0] y;

        begin

            font_row = 5'b00000;

            case (ch)

                "A": begin
                    case (y)
                        0: font_row = 5'b01110;
                        1: font_row = 5'b10001;
                        2: font_row = 5'b10001;
                        3: font_row = 5'b11111;
                        4: font_row = 5'b10001;
                        5: font_row = 5'b10001;
                        6: font_row = 5'b10001;
                        default: font_row = 5'b00000;
                    endcase
                end

                "C": begin
                    case (y)
                        0: font_row = 5'b01110;
                        1: font_row = 5'b10001;
                        2: font_row = 5'b10000;
                        3: font_row = 5'b10000;
                        4: font_row = 5'b10000;
                        5: font_row = 5'b10001;
                        6: font_row = 5'b01110;
                        default: font_row = 5'b00000;
                    endcase
                end

                "D": begin
                    case (y)
                        0: font_row = 5'b11110;
                        1: font_row = 5'b10001;
                        2: font_row = 5'b10001;
                        3: font_row = 5'b10001;
                        4: font_row = 5'b10001;
                        5: font_row = 5'b10001;
                        6: font_row = 5'b11110;
                        default: font_row = 5'b00000;
                    endcase
                end

                "E": begin
                    case (y)
                        0: font_row = 5'b11111;
                        1: font_row = 5'b10000;
                        2: font_row = 5'b10000;
                        3: font_row = 5'b11110;
                        4: font_row = 5'b10000;
                        5: font_row = 5'b10000;
                        6: font_row = 5'b11111;
                        default: font_row = 5'b00000;
                    endcase
                end

                "F": begin
                    case (y)
                        0: font_row = 5'b11111;
                        1: font_row = 5'b10000;
                        2: font_row = 5'b10000;
                        3: font_row = 5'b11110;
                        4: font_row = 5'b10000;
                        5: font_row = 5'b10000;
                        6: font_row = 5'b10000;
                        default: font_row = 5'b00000;
                    endcase
                end

                "G": begin
                    case (y)
                        0: font_row = 5'b01110;
                        1: font_row = 5'b10001;
                        2: font_row = 5'b10000;
                        3: font_row = 5'b10111;
                        4: font_row = 5'b10001;
                        5: font_row = 5'b10001;
                        6: font_row = 5'b01110;
                        default: font_row = 5'b00000;
                    endcase
                end

                "H": begin
                    case (y)
                        0: font_row = 5'b10001;
                        1: font_row = 5'b10001;
                        2: font_row = 5'b10001;
                        3: font_row = 5'b11111;
                        4: font_row = 5'b10001;
                        5: font_row = 5'b10001;
                        6: font_row = 5'b10001;
                        default: font_row = 5'b00000;
                    endcase
                end

                "I": begin
                    case (y)
                        0: font_row = 5'b11111;
                        1: font_row = 5'b00100;
                        2: font_row = 5'b00100;
                        3: font_row = 5'b00100;
                        4: font_row = 5'b00100;
                        5: font_row = 5'b00100;
                        6: font_row = 5'b11111;
                        default: font_row = 5'b00000;
                    endcase
                end

                "K": begin
                    case (y)
                        0: font_row = 5'b10001;
                        1: font_row = 5'b10010;
                        2: font_row = 5'b10100;
                        3: font_row = 5'b11000;
                        4: font_row = 5'b10100;
                        5: font_row = 5'b10010;
                        6: font_row = 5'b10001;
                        default: font_row = 5'b00000;
                    endcase
                end

                "L": begin
                    case (y)
                        0: font_row = 5'b10000;
                        1: font_row = 5'b10000;
                        2: font_row = 5'b10000;
                        3: font_row = 5'b10000;
                        4: font_row = 5'b10000;
                        5: font_row = 5'b10000;
                        6: font_row = 5'b11111;
                        default: font_row = 5'b00000;
                    endcase
                end

                "N": begin
                    case (y)
                        0: font_row = 5'b10001;
                        1: font_row = 5'b11001;
                        2: font_row = 5'b10101;
                        3: font_row = 5'b10011;
                        4: font_row = 5'b10001;
                        5: font_row = 5'b10001;
                        6: font_row = 5'b10001;
                        default: font_row = 5'b00000;
                    endcase
                end

                "O": begin
                    case (y)
                        0: font_row = 5'b01110;
                        1: font_row = 5'b10001;
                        2: font_row = 5'b10001;
                        3: font_row = 5'b10001;
                        4: font_row = 5'b10001;
                        5: font_row = 5'b10001;
                        6: font_row = 5'b01110;
                        default: font_row = 5'b00000;
                    endcase
                end

                "P": begin
                    case (y)
                        0: font_row = 5'b11110;
                        1: font_row = 5'b10001;
                        2: font_row = 5'b10001;
                        3: font_row = 5'b11110;
                        4: font_row = 5'b10000;
                        5: font_row = 5'b10000;
                        6: font_row = 5'b10000;
                        default: font_row = 5'b00000;
                    endcase
                end

                "R": begin
                    case (y)
                        0: font_row = 5'b11110;
                        1: font_row = 5'b10001;
                        2: font_row = 5'b10001;
                        3: font_row = 5'b11110;
                        4: font_row = 5'b10100;
                        5: font_row = 5'b10010;
                        6: font_row = 5'b10001;
                        default: font_row = 5'b00000;
                    endcase
                end

                "S": begin
                    case (y)
                        0: font_row = 5'b01111;
                        1: font_row = 5'b10000;
                        2: font_row = 5'b10000;
                        3: font_row = 5'b01110;
                        4: font_row = 5'b00001;
                        5: font_row = 5'b00001;
                        6: font_row = 5'b11110;
                        default: font_row = 5'b00000;
                    endcase
                end

                "T": begin
                    case (y)
                        0: font_row = 5'b11111;
                        1: font_row = 5'b00100;
                        2: font_row = 5'b00100;
                        3: font_row = 5'b00100;
                        4: font_row = 5'b00100;
                        5: font_row = 5'b00100;
                        6: font_row = 5'b00100;
                        default: font_row = 5'b00000;
                    endcase
                end

                "U": begin
                    case (y)
                        0: font_row = 5'b10001;
                        1: font_row = 5'b10001;
                        2: font_row = 5'b10001;
                        3: font_row = 5'b10001;
                        4: font_row = 5'b10001;
                        5: font_row = 5'b10001;
                        6: font_row = 5'b01110;
                        default: font_row = 5'b00000;
                    endcase
                end

                "W": begin
                    case (y)
                        0: font_row = 5'b10001;
                        1: font_row = 5'b10001;
                        2: font_row = 5'b10001;
                        3: font_row = 5'b10101;
                        4: font_row = 5'b10101;
                        5: font_row = 5'b11011;
                        6: font_row = 5'b10001;
                        default: font_row = 5'b00000;
                    endcase
                end

                "M": begin
                    case (y)
                        0: font_row = 5'b10001;
                        1: font_row = 5'b11011;
                        2: font_row = 5'b10101;
                        3: font_row = 5'b10101;
                        4: font_row = 5'b10001;
                        5: font_row = 5'b10001;
                        6: font_row = 5'b10001;
                        default: font_row = 5'b00000;
                    endcase
                end

                "X": begin
                    case (y)
                        0: font_row = 5'b10001;
                        1: font_row = 5'b10001;
                        2: font_row = 5'b01010;
                        3: font_row = 5'b00100;
                        4: font_row = 5'b01010;
                        5: font_row = 5'b10001;
                        6: font_row = 5'b10001;
                        default: font_row = 5'b00000;
                    endcase
                end

                "1": begin
                    case (y)
                        0: font_row = 5'b00100;
                        1: font_row = 5'b01100;
                        2: font_row = 5'b00100;
                        3: font_row = 5'b00100;
                        4: font_row = 5'b00100;
                        5: font_row = 5'b00100;
                        6: font_row = 5'b01110;
                        default: font_row = 5'b00000;
                    endcase
                end

                "2": begin
                    case (y)
                        0: font_row = 5'b01110;
                        1: font_row = 5'b10001;
                        2: font_row = 5'b00001;
                        3: font_row = 5'b00010;
                        4: font_row = 5'b00100;
                        5: font_row = 5'b01000;
                        6: font_row = 5'b11111;
                        default: font_row = 5'b00000;
                    endcase
                end

                "3": begin
                    case (y)
                        0: font_row = 5'b01110;
                        1: font_row = 5'b10001;
                        2: font_row = 5'b00001;
                        3: font_row = 5'b00110;
                        4: font_row = 5'b00001;
                        5: font_row = 5'b10001;
                        6: font_row = 5'b01110;
                        default: font_row = 5'b00000;
                    endcase
                end

                "4": begin
                    case (y)
                        0: font_row = 5'b00010;
                        1: font_row = 5'b00110;
                        2: font_row = 5'b01010;
                        3: font_row = 5'b10010;
                        4: font_row = 5'b11111;
                        5: font_row = 5'b00010;
                        6: font_row = 5'b00010;
                        default: font_row = 5'b00000;
                    endcase
                end

                "5": begin
                    case (y)
                        0: font_row = 5'b11111;
                        1: font_row = 5'b10000;
                        2: font_row = 5'b11110;
                        3: font_row = 5'b00001;
                        4: font_row = 5'b00001;
                        5: font_row = 5'b10001;
                        6: font_row = 5'b01110;
                        default: font_row = 5'b00000;
                    endcase
                end

                "7": begin
                    case (y)
                        0: font_row = 5'b11111;
                        1: font_row = 5'b00001;
                        2: font_row = 5'b00010;
                        3: font_row = 5'b00100;
                        4: font_row = 5'b01000;
                        5: font_row = 5'b01000;
                        6: font_row = 5'b01000;
                        default: font_row = 5'b00000;
                    endcase
                end

                "[": begin
                    case (y)
                        0: font_row = 5'b01110;
                        1: font_row = 5'b01000;
                        2: font_row = 5'b01000;
                        3: font_row = 5'b01000;
                        4: font_row = 5'b01000;
                        5: font_row = 5'b01000;
                        6: font_row = 5'b01110;
                        default: font_row = 5'b00000;
                    endcase
                end

                "]": begin
                    case (y)
                        0: font_row = 5'b01110;
                        1: font_row = 5'b00010;
                        2: font_row = 5'b00010;
                        3: font_row = 5'b00010;
                        4: font_row = 5'b00010;
                        5: font_row = 5'b00010;
                        6: font_row = 5'b01110;
                        default: font_row = 5'b00000;
                    endcase
                end

                default:
                    font_row = 5'b00000;

            endcase

        end
    endfunction

    wire [4:0] sym_bits = font_row(sym_char, sym_row);

    wire sym_pixel =
        (display_has_x | display_has_o) &&
        in_sym_x &&
        in_sym_y &&
        sym_bits[4 - sym_col[2:0]];

    wire [4:0] text_font_bits = font_row(active_char, font_y);

    wire text_font_pixel =
        ((text_local_x % TEXT_CHAR_W) < 10) &&
        text_font_bits[4 - ((text_local_x % TEXT_CHAR_W) >> 1)];

    /*
     * VIDEO
     *
     * BLUE:   selected-cell border during X's turn
     * RED:    selected-cell border during O's turn
     * GREEN:  winning-line border
     * WHITE:  board grid lines, X / O marks, and all text
     */

    reg red;
    reg green;
    reg blue;

    always @(*) begin

        red   = 1'b0;
        green = 1'b0;
        blue  = 1'b0;

        if (display_on) begin

            if (inside_grid) begin

                if (win_border) begin

                    red   = 1'b0;
                    green = 1'b1;
                    blue  = 1'b0;

                end

                else if (selected_border) begin

                    if (!current_player) begin
                        // X's turn: blue outline
                        red   = 1'b0;
                        green = 1'b0;
                        blue  = 1'b1;
                    end
                    else begin
                        // O's turn: red outline
                        red   = 1'b1;
                        green = 1'b0;
                        blue  = 1'b0;
                    end

                end

                else if (normal_grid) begin

                    red   = 1'b1;
                    green = 1'b1;
                    blue  = 1'b1;

                end

                else if (sym_pixel) begin

                    red   = 1'b1;
                    green = 1'b1;
                    blue  = 1'b1;

                end
            end

            else if (inside_text_any && text_font_pixel) begin

                red   = 1'b1;
                green = 1'b1;
                blue  = 1'b1;

            end
        end
    end

    /*
     * VGA OUTPUT
     */

    assign uo_out[7] = hsync;
    assign uo_out[3] = vsync;

    assign uo_out[6] = red;
    assign uo_out[5] = green;
    assign uo_out[4] = blue;

    assign uo_out[2] = red;
    assign uo_out[1] = green;
    assign uo_out[0] = blue;

endmodule
