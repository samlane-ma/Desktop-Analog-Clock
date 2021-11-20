using Gtk, Gdk;
using Cairo;
using Math;

namespace DesktopClock {

    public class DesktopClockWindow : Gtk.ApplicationWindow {

        private GLib.Settings app_settings;
        private Gdk.Visual? visual;
        private DrawingArea drawing_area;
        private const int XCOORD = 0;
        private const int YCOORD = 1;
        private int center;
        private int scale;
        private int winx;
        private int winy;
        private int clock_number;
        private double transp;
        private bool showseconds;
        private string handcolor;
        private string facecolor;
        private string secondscolor;
        private string framecolor;

        public DesktopClockWindow (Gtk.Application application) {
            GLib.Object (application: application);
            app_settings = new GLib.Settings ("com.github.samlane-ma.desktop-analog-clock");
            set_app_paintable(true);
            var screen = get_screen();
            visual = screen.get_rgba_visual();
            if (visual != null && screen.is_composited()){
                set_visual(visual);
            }
            set_type_hint(Gdk.WindowTypeHint.DESKTOP);
            set_decorated(false);
			drawing_area = new DrawingArea ();
            drawing_area.draw.connect (on_draw);
            add (drawing_area);
            load_settings("all");
            Timeout.add_seconds_full(GLib.Priority.LOW,1, () => {
                queue_draw();
                return true;
             } );
            app_settings.changed.connect((key) => {
                load_settings(key);
                queue_draw();
            });
			this.show_all();
        }

        private void load_settings(string key){
            string[] appearances = {"color-hands", "color-face", "color-frame", "color-seconds",
                                    "transparency", "show-seconds", "clock-number"};
            string[] coords = {"x", "y" };
            if (key == "all" || key in appearances) {
                handcolor = app_settings.get_string("color-hands");
                facecolor = app_settings.get_string("color-face");
                framecolor = app_settings.get_string("color-frame");
                secondscolor = app_settings.get_string("color-seconds");
                showseconds = app_settings.get_boolean("show-seconds");
                clock_number = app_settings.get_int("clock-number");
            }
            if (key == "all" || key == "scale") {
                scale = app_settings.get_int("scale");
                center = scale / 2;
                resize(scale, scale);
            }
            if (key == "all" || key in coords ) {
                winx = app_settings.get_int("x");
                winy = app_settings.get_int("y");
                move(winx, winy);
            }
            if (key == "all" || key == "transparency") {
                transp = app_settings.get_double("transparency");
                drawing_area.set_opacity(transp);
            }
            if (key == "all" || key == "show-desktop") {
                if (!app_settings.get_boolean("show-desktop")){
                    application.quit();
                }
            }
        }

        private bool on_draw (Widget da, Context ctx) {
            double number_offset;
            var current_time = new DateTime.now_local();
            draw_face(ctx);
            draw_frame(ctx);
            if (clock_number % 2 == 1) {
                draw_marks(ctx);
                number_offset = 0.76;
            } else {
                number_offset = 0.82;
            }
            if (clock_number > 2) {
                draw_numbers(ctx, number_offset, true);
            } else {
                draw_numbers(ctx, number_offset, false);
            }
            draw_hands(ctx, current_time);
            return true;
        }

        private void draw_face(Context ctx) {
            Gdk.RGBA color = Gdk.RGBA();
            color.parse(facecolor);
            ctx.set_source_rgba(color.red, color.green, color.blue, color.alpha);
            ctx.set_line_width (scale / 50);
            ctx.arc(center, center, (scale - 2) / 2, 0, 2 * Math.PI);
            ctx.fill();
        }

        private void draw_frame(Context ctx) {
            Gdk.RGBA color = Gdk.RGBA();
            color.parse(framecolor);
            ctx.set_line_width (scale / 50);
            ctx.set_source_rgba(color.red, color.green, color.blue, color.alpha);
            ctx.arc(center, center, (scale - scale / 50 -1) / 2, 0, 2 * Math.PI);
            ctx.stroke();
        }

        private void draw_marks(Context ctx) {
            Gdk.RGBA color = Gdk.RGBA();
            color.parse(framecolor);
            ctx.set_source_rgba(color.red, color.green, color.blue, color.alpha);
            ctx.set_line_cap(Cairo.LineCap.SQUARE);
            for (int i = 0; i < 60; i++) {
                double len;
                double linewid;
                if (i % 5 == 0) {
                    len = 0.89;
                    linewid = scale / 90 + 1;
                }
                else {
                    len = 0.93;
                    linewid = scale / 180 + 1;
                }
                ctx.set_line_width(linewid);
                double m_x = get_coord(XCOORD, i, scale / 2 * 0.98, scale / 2);
                double m_y = get_coord(YCOORD, i, scale / 2 * 0.98, scale / 2);
                double s_x = get_coord(XCOORD, i, scale / 2 * len, scale / 2);
                double s_y = get_coord(YCOORD, i, scale / 2 * len, scale / 2);
                ctx.move_to (m_x, m_y);
                ctx.line_to (s_x, s_y);
                ctx.stroke();
            }
        }

        private void draw_numbers (Context ctx, double offset, bool use_roman) {
            Gdk.RGBA color = Gdk.RGBA();
            string[] roman = {"I", "II", "III", "IV", "V", "VI",
                              "VII", "VIII", "IX", "X", "XI", "XII"};
            string dtxt;
            color.parse(framecolor);
            ctx.set_source_rgba(color.red, color.green, color.blue, color.alpha);
            ctx.set_font_size(scale / 13);
            ctx.select_font_face("Sans", Cairo.FontSlant.NORMAL, Cairo.FontWeight.BOLD);
            for (int i=0; i < 12; i++) {
                double radians = i * (Math.PI * 2) / 12;
                int number = i + 3;
                if (number > 12){
                    number -= 12;
                }
                if (use_roman) {
                    dtxt = roman[number - 1];
                } else {
                    dtxt = number.to_string();
                }
                Cairo.TextExtents extents;
                ctx.text_extents (dtxt, out extents);
                int t_x = (int) (center + (center * offset) * cos(radians));
                int t_y = (int) (center + (center * offset) * sin(radians));
                ctx.move_to(t_x - extents.width /2 , t_y + extents.height /2);
                ctx.show_text(dtxt);
            }
        }

        private void draw_hands(Context ctx, DateTime current_time) {
            Gdk.RGBA color = Gdk.RGBA();

            int hour = current_time.get_hour();
            int minute = current_time.get_minute();
            int seconds = (int)current_time.get_seconds();

            color.parse(handcolor);
            ctx.set_source_rgba(color.red, color.green, color.blue, color.alpha);
            ctx.set_line_width(scale / 50);
            ctx.set_line_cap(Cairo.LineCap.ROUND);

            ctx.move_to(center, center);
            ctx.line_to(get_coord(XCOORD, hour * 5, scale / 2* 0.50, scale / 2),
                        get_coord(YCOORD, hour * 5, scale / 2* 0.50, scale / 2));
            ctx.stroke();

            ctx.move_to(center, center);
            ctx.line_to(get_coord(XCOORD, minute, scale / 2 * 0.72, scale / 2),
                        get_coord(YCOORD, minute, scale / 2 * 0.72, scale / 2));
            ctx.stroke();

            if (showseconds) {
                color.parse(secondscolor);
                ctx.set_source_rgba(color.red, color.green, color.blue, color.alpha);
                if ((scale / 70 - 2) < 1){
                    ctx.set_line_width(1);
                }
                else {
                    ctx.set_line_width(scale / 70 - 1);
                }
                ctx.move_to(center, center);
                ctx.line_to(get_coord(XCOORD, seconds, scale / 2 * 0.79, scale / 2),
                        get_coord(YCOORD, seconds, scale / 2 * 0.79, scale / 2));
                ctx.stroke();
            }
            ctx.arc(scale / 2, scale / 2, scale / 120 + 2, 0, 2 * Math.PI);
            ctx.fill();
        }

        private double get_coord(int coord_type, int hand_position, double length, double center) {

            hand_position -= 15;
            if (hand_position < 0) {
                hand_position += 60;
            }
            double radians = (hand_position * Math.PI * 2 / 60);
            if (coord_type == XCOORD) {
                return center + length * Math.cos(radians);
            }
            else if (coord_type == YCOORD) {
                return center + length * Math.sin(radians);
            }
            else{
                return 0;
            }
        }
    }

    public class Application : Gtk.Application {

        private DesktopClockWindow window;

        public Application () {
            application_id = "org.gtk.exampleapp";
            flags |= GLib.ApplicationFlags.HANDLES_COMMAND_LINE;
             add_main_option ("quit", 'q', OptionFlags.NONE, OptionArg.NONE,
                              "Quit the desktop clock (if running)", null);
        }

        public override void activate () {
            if (window == null) {
				window = new DesktopClockWindow (this);
                window.present ();
			}
        }

		public override int command_line (ApplicationCommandLine commands) {
            var options = commands.get_options_dict();
            if (options.contains("quit")) {
                if (window != null) {
                    quit();
                }
                else {
                    return 0;
                }
            }
			activate();
			return 0;
		}
    }

	public static int main (string[] args) {
        var application = new Application ();
        return application.run (args);
    }
}


