package ucla.nesl.barometersensing;

import android.app.Activity;
import android.widget.LinearLayout;
import android.widget.TextView;

import java.util.ArrayList;

/**
 * Created by timestring on 11/27/14.
 */
public class TextViewBuf {
    private static ArrayList<TextViewBuf> list = new ArrayList<TextViewBuf>();

    private TextView text;
    private String bufStr = null;

    public static TextViewBuf createText(LinearLayout layout, Activity activity, String str) {
        TextViewBuf re = new TextViewBuf();
        re.text = new TextView(activity);
        layout.addView(re.text);
        re.text.setText(str);
        list.add(re);
        return re;
    }

    public static void update() {
        for (TextViewBuf b : list) {
            if (b.bufStr != null) {
                b.text.setText(b.bufStr);
                b.bufStr = null;
            }
        }
    }

    public void setStr(String str) {
        bufStr = str;
    }
}
