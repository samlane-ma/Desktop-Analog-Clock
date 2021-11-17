/*
 *  Desktop Clock Applet for the Budgie Panel
 */
 
using Gtk, Gdk, Cairo;

namespace DesktopClock {

    private string moduledir;
    private string clockpath;

    public class Plugin : Budgie.Plugin, Peas.ExtensionBase {

        public Budgie.Applet get_panel_widget(string uuid){
            var info = this.get_plugin_info();
            moduledir = info.get_module_dir();
            return new DesktopClockApplet(uuid);
        }
    }

    public class DesktopClockSettings : Grid {

        private GLib.Settings app_settings;

        public DesktopClockSettings(GLib.Settings? settings) {

            app_settings = new GLib.Settings ("com.github.samlane-ma.desktop-analog-clock");

            Switch switch_show = new Switch();
            Label label_show = new Label("Show on desktop");
            Label spacer = new Label("");
            Stack stack = new Stack();
            Grid grid_desktop = new Grid();
            Grid grid_appearance = new Grid();
            StackSwitcher switcher = new StackSwitcher();
            Adjustment x_adj = new Adjustment(200, 1, 10000, 1, 10, 10);
            Adjustment y_adj = new Adjustment(200, 1, 10000, 1, 10, 10);
            Adjustment size_adj = new Adjustment(200, 1, 10000, 1, 10, 10);
            Adjustment clock_adj = new Adjustment(1, 1, 5, 1, 1, 1);
            Scale scale_transp = new Scale.with_range(Orientation.HORIZONTAL, 0.0, 1.0, 0.05);
            SpinButton spin_x = new SpinButton(x_adj, 1.0, 0);
            SpinButton spin_y = new SpinButton(y_adj, 1.0, 0);
            SpinButton spin_size = new SpinButton(size_adj, 1.0, 0);
            SpinButton clock_number = new SpinButton(clock_adj, 1.0, 0);
            Switch switch_seconds = new Switch();
            Scale face_alpha = new Scale.with_range(Orientation.HORIZONTAL, 0.0, 1.0, 0.05);
            RGBA color;
            string loadcolor;

            string[] labels = {"", "X position", "Y Position", "Clock Size", "Transparency"};
            grid_desktop.set_column_spacing(6);
            grid_desktop.set_row_spacing(6);
            for (int i = 0; i < 5; i++){
                Label label = new Label(labels[i]);
                label.set_halign(Gtk.Align.END);
                grid_desktop.attach(label, 0, i, 1, 1);
            }
            grid_desktop.attach(spin_x, 1, 1, 1, 1);
            grid_desktop.attach(spin_y, 1, 2, 1, 1);
            grid_desktop.attach(spin_size, 1, 3, 1, 1);
            grid_desktop.attach(scale_transp, 1, 4, 1, 1);


            labels = {"", "Clock Number", "Face Color", "Face Alpha", "Frame Color", "Hand Color", "Seconds Color", "Show Seconds"};
            grid_appearance.set_column_spacing(6);
            grid_appearance.set_row_spacing(6);
            grid_appearance.set_column_homogeneous(true);
            for (int i = 0; i < 8; i++){
                Label label = new Label(labels[i]);
                label.set_halign(Gtk.Align.END);
                grid_appearance.attach(label, 0, i, 1, 1);
            }

            scale_transp.set_value(app_settings.get_double("transparency"));
            scale_transp.value_changed.connect(update_transp);

            color = RGBA();

            loadcolor = app_settings.get_string("color-face");
            color.parse(loadcolor);
            ColorButton button_face = new ColorButton.with_rgba(color);
            face_alpha.set_value(color.alpha);
            button_face.color_set.connect (() => 
                             { on_color_changed(button_face,"color-face");
                               update_face_alpha(face_alpha.get_value(), button_face);
                             });

            loadcolor = app_settings.get_string("color-frame");
            color.parse(loadcolor);
            ColorButton button_frame = new ColorButton.with_rgba(color);
            button_frame.color_set.connect (() => 
                             { on_color_changed(button_frame,"color-frame");});

            loadcolor = app_settings.get_string("color-hands");
            color.parse(loadcolor);
            ColorButton button_hands = new ColorButton.with_rgba(color);
            button_hands.color_set.connect (() => 
                             { on_color_changed(button_hands,"color-hands");});

            loadcolor = app_settings.get_string("color-seconds");
            color.parse(loadcolor);
            ColorButton button_seconds = new ColorButton.with_rgba(color);
            button_seconds.color_set.connect (() => 
                             { on_color_changed(button_seconds,"color-seconds");});

            face_alpha.value_changed.connect(() => { update_face_alpha(face_alpha.get_value(), button_face); });

            switch_seconds.set_halign(Align.END);
            grid_appearance.attach(clock_number, 1, 1, 1, 1);
            grid_appearance.attach(button_face, 1, 2, 1, 1);
            grid_appearance.attach(face_alpha, 1, 3, 1, 1);
            grid_appearance.attach(button_frame, 1, 4, 1, 1);
            grid_appearance.attach(button_hands, 1, 5, 1, 1);
            grid_appearance.attach(button_seconds, 1, 6, 1, 1);
            grid_appearance.attach(switch_seconds, 1, 7, 1, 1);

            stack.set_transition_type(StackTransitionType.SLIDE_LEFT_RIGHT);
            stack.add_titled(grid_desktop, "desktop", "Desktop");
            stack.add_titled(grid_appearance, "appearance", "Appearance");
            switcher.set_stack(stack);
            switch_show.set_halign(Gtk.Align.END);
            this.attach(label_show, 0, 0, 1, 1);
            this.attach(switch_show, 1, 0, 1, 1);
            this.attach(spacer, 0, 1, 2, 1);
            this.attach(switcher, 0, 2, 2, 1);
            this.attach(stack, 0, 3, 2, 1);

            app_settings.bind("show-seconds",switch_seconds,"active",SettingsBindFlags.DEFAULT);
            app_settings.bind("show-desktop",switch_show,"active",SettingsBindFlags.DEFAULT);
            app_settings.bind("x",spin_x,"value",SettingsBindFlags.DEFAULT);
            app_settings.bind("y",spin_y,"value",SettingsBindFlags.DEFAULT);
            app_settings.bind("scale",spin_size,"value",SettingsBindFlags.DEFAULT);
            app_settings.bind("clock-number", clock_number, "value", SettingsBindFlags.DEFAULT);

            this.show_all();
        }

        private void update_transp (Gtk.Range scale) {
            app_settings.set_double("transparency", scale.get_value());
        }

        private void update_face_alpha(double value, ColorButton button) {
            uint16 alpha = (uint16) (65535 * value);
            button.set_alpha(alpha);
            RGBA color = button.get_rgba();
            app_settings.set_string("color-face", color.to_string());
        }

        private void on_color_changed(ColorButton button, string part) {
            Gdk.RGBA c = button.get_rgba();
            app_settings.set_string(part, c.to_string());
        }
        
    }

    public class DesktopClockApplet : Budgie.Applet {

        public string uuid { public set; public get; }
        private GLib.Settings settings = new GLib.Settings ("com.github.samlane-ma.desktop-analog-clock");
        private GLib.Settings? panel_settings;
        private GLib.Settings? currpanelsubject_settings;
        private ulong panel_signal;

        public DesktopClockApplet(string uuid) {

            clockpath = moduledir.concat("/desktop-clock");

            settings.changed["show-desktop"].connect( () => 
                                { start_stop_desktop(clockpath, settings.get_boolean("show-desktop")); });

            if (settings.get_boolean("show-desktop")) {
                start_stop_desktop(clockpath, true);
            }
            Idle.add(() => { watch_applet(uuid); 
                return false;});
        }

        private void start_stop_desktop(string cmd, bool run) {
            if (run) {
                try {
                    Process.spawn_command_line_async(cmd);
                }
                catch (SpawnError e) {
                    /* nothing to be done */
                }
            }
            else {
                try {
                    cmd.concat(" -q");
                    Process.spawn_command_line_async(cmd);
                }
                catch (SpawnError e) {
                    /* nothing to be done */
                }
            }
        }
        private bool find_applet(string find_uuid, string[] applet_list) {
            // Search panel applets for the given uuid
            for (int i = 0; i < applet_list.length; i++) {
                if (applet_list[i] == find_uuid) {
                    return true;
                }
            }
            return false;
        }

        private void watch_applet(string find_uuid) {
            // Check if the applet is still on the panel and ends cleanly if not
            string[] applets;
            string soluspath = "com.solus-project.budgie-panel";
            panel_settings = new GLib.Settings(soluspath);
            string[] allpanels_list = panel_settings.get_strv("panels");
            foreach (string p in allpanels_list) {
                string panelpath = "/com/solus-project/budgie-panel/panels/".concat("{", p, "}/");
                currpanelsubject_settings = new GLib.Settings.with_path(
                    soluspath + ".panel", panelpath
                );
                applets = currpanelsubject_settings.get_strv("applets");
                if (find_applet(find_uuid, applets)) {
                     panel_signal = currpanelsubject_settings.changed["applets"].connect(() => {
                        applets = currpanelsubject_settings.get_strv("applets");
                        if (!find_applet(find_uuid, applets)) {
                            currpanelsubject_settings.disconnect(panel_signal);
                            settings.set_boolean("show-desktop", false);
                            start_stop_desktop(clockpath, false);
                        }
                    });
                }
            }
        }

        public override bool supports_settings() {
            return true;
        }

        public override Gtk.Widget? get_settings_ui() {
            return new DesktopClockSettings(this.get_applet_settings(uuid));
        }

    }
}

[ModuleInit]
public void peas_register_types(TypeModule module) {

    // boilerplate - all modules need this
    var objmodule = module as Peas.ObjectModule;
    objmodule.register_extension_type(typeof(Budgie.Plugin), typeof(DesktopClock.Plugin));
}
