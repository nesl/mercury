
// --- CONVERTING COLORS ---
function hslToRgb(h, s, l){
	var r, g, b;

	h = h % 1.0;
	if (h < 0.0)
		h += 1.0;
	if (h >= 1.0)
		h -= 1.0;
	if(s == 0){
		r = g = b = Math.round(l * 255); // achromatic
	}else{
		function hue2rgb(p, q, t){
			if(t < 0) t += 1;
			if(t > 1) t -= 1;
			if(t < 1/6) return p + (q - p) * 6 * t;
			if(t < 1/2) return q;
			if(t < 2/3) return p + (q - p) * (2/3 - t) * 6;
			return p;
		}

		var q = l < 0.5 ? l * (1 + s) : l + s - l * s;
		var p = 2 * l - q;
		r = Math.round( hue2rgb(p, q, h + 1/3) * 255 );
		g = Math.round( hue2rgb(p, q, h)       * 255 );
		b = Math.round( hue2rgb(p, q, h - 1/3) * 255 );
	}
	return "#" + ((1 << 24) + (r << 16) + (g << 8) + b).toString(16).slice(1);
}
