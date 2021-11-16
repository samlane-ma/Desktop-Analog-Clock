using Gtk, Gdk;
using Cairo;
using Math;

namespace DesktopClock {

    public class DesktopClockWindow : Gtk.ApplicationWindow {

        // to quit: application.quit();
        private GLib.Settings app_settings;
        private const int SIZE = 30;
        private Gdk.Visual? visual;
        DrawingArea drawing_area;
        int center_x;
        int center_y;
        int scale;
        int seconds;
        int minute;
        int hour;
        int winx;
        int winy;
        int clock_number;
        double transp;
        bool showseconds;
        string handcolor;
        string facecolor;
        string secondscolor;
        string framecolor;

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
\
        private bool on_draw (Widget da, Context ctx) {
            double number_offset;
            center_x = scale / 2;
            center_y = scale / 2;
            var current_time = new DateTime.now_local();
            hour = current_time.get_hour();
            minute = current_time.get_minute();
            seconds = (int)current_time.get_seconds();

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
            draw_hands(ctx);

            return true;
        }

        private void draw_face(Context ctx) {
            Gdk.RGBA color = Gdk.RGBA();
            color.parse(facecolor);
            ctx.set_source_rgba(color.red, color.green, color.blue, color.alpha);
            ctx.set_line_width (scale / 50);
            ctx.arc(center_x, center_y, (scale - 2) / 2, 0, 2 * Math.PI);
            ctx.fill();
        }

        private void draw_frame(Context ctx) {
            Gdk.RGBA color = Gdk.RGBA();
            color.parse(framecolor);
            ctx.set_line_width (scale / 50);
            ctx.set_source_rgba(color.red, color.green, color.blue, color.alpha);
            ctx.arc(center_x, center_y, (scale - scale / 50) / 2, 0, 2 * Math.PI);
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
                double m_x = get_coord("x", i, scale / 2 * 0.98, scale / 2);
                double m_y = get_coord("y", i, scale / 2 * 0.98, scale / 2);
                double s_x = get_coord("x", i, scale / 2 * len, scale / 2);
                double s_y = get_coord("y", i, scale / 2 * len, scale / 2);
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
                int t_x = (int) (center_x + (center_y * offset) * cos(radians));
                int t_y = (int) (center_y + (center_y * offset) * sin(radians));
                ctx.move_to(t_x - extents.width /2 , t_y + extents.height /2);
                ctx.show_text(dtxt);
            }
        }

        private void draw_hands(Context ctx) {
            Gdk.RGBA color = Gdk.RGBA();

            color.parse(handcolor);
            ctx.set_source_rgba(color.red, color.green, color.blue, color.alpha);
            ctx.set_line_width(scale / 50);
            ctx.set_line_cap(Cairo.LineCap.ROUND);

            ctx.move_to(center_x, center_y);
            ctx.line_to(get_coord("x", hour * 5, scale / 2* 0.50, scale / 2),
                        get_coord("y", hour * 5, scale / 2* 0.50, scale / 2));
            ctx.stroke();

            ctx.move_to(center_x, center_y);
            ctx.line_to(get_coord("x", minute, scale / 2 * 0.72, scale / 2),
                        get_coord("y", minute, scale / 2 * 0.72, scale / 2));
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
                ctx.move_to(center_x, center_y);
                ctx.line_to(get_coord("x", seconds, scale / 2 * 0.79, scale / 2),
                        get_coord("y", seconds, scale / 2 * 0.79, scale / 2));
                ctx.stroke();
            }
            ctx.arc(scale / 2, scale / 2, scale / 120 + 2, 0, 2 * Math.PI);
            ctx.fill();
        }

        private double get_coord(string c_type, int hand_position, double length, double center) {

            hand_position -= 15;
            if (hand_position < 0) {
                hand_position += 60;
            }
            double radians = (hand_position * 3.14159 * 2 / 60);
            if (c_type == "x") {
                return center + length * Math.cos(radians);
            }
            else if (c_type == "y") {
                return center + length * Math.sin(radians);
            }
            return 0;
        }
    
    }

    public class Application : Gtk.Application {

        private DesktopClockWindow window;

        public Application () {
            application_id = "org.gtk.exampleapp";
            flags |= GLib.ApplicationFlags.HANDLES_COMMAND_LINE;
             add_main_option ("quit", 'q', OptionFlags.NONE, OptionArg.NONE,
                              "Show the version of the program and exit", null);
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


