package {{PACKAGE}};

import android.app.Activity;
import android.graphics.Color;
import android.os.Bundle;
import android.view.Gravity;
import android.widget.LinearLayout;
import android.widget.TextView;

/**
 * Minimal BuildAPK starter: a single Activity that shows a greeting.
 * No layout XML needed — the UI is built in code to keep the template tiny.
 */
public class MainActivity extends Activity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setGravity(Gravity.CENTER);
        root.setBackgroundColor(Color.parseColor("#FAF3E8"));
        root.setPadding(48, 48, 48, 48);

        TextView title = new TextView(this);
        title.setText("Hello, BuildAPK!");
        title.setTextSize(28);
        title.setTextColor(Color.parseColor("#1A1A1A"));
        title.setGravity(Gravity.CENTER);
        root.addView(title);

        TextView sub = new TextView(this);
        sub.setText("Built with zero Gradle.");
        sub.setTextSize(16);
        sub.setTextColor(Color.parseColor("#8A7B5C"));
        sub.setGravity(Gravity.CENTER);
        sub.setPadding(0, 24, 0, 0);
        root.addView(sub);

        setContentView(root);
    }
}
