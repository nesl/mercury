package ucla.nesl.barometersensing;

import java.text.SimpleDateFormat;
import java.util.Date;

/**
 * Created by timestring on 10/19/14.
 */
public class TimeString {
    private SimpleDateFormat formatForFile = new SimpleDateFormat("yyyyMMdd_HHmmss");
    private SimpleDateFormat formatForDisplay = new SimpleDateFormat("MM/dd HH:mm:ss");

    public String currentTimeForFile() {
        return formatForFile.format(new Date());
    }

    public String currentTimeForDisplay() {
        return formatForDisplay.format(new Date());
    }

    public String ms2watch(long ms) {
        ms /= 1000;
        int s = (int)(ms % 60);
        ms /= 60;
        int m = (int)(ms % 60);
        ms /= 60;
        int h = (int)ms;
        if (h > 0)
            return String.format("%d:%02d:%02d", h, m, s);
        else
            return String.format("%d:%02d", m, s);
    }
}
