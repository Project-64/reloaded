#!/usr/bin/ruby

require 'getoptlong'

opts = GetoptLong.new(
	[ '--help', '-h', GetoptLong::NO_ARGUMENT ],
	[ '--outfile', '-o', GetoptLong::REQUIRED_ARGUMENT ]
)

infile = nil
outfile = "font.svg"

opts.each do |opt, arg|
	case opt
	when '--help'
		puts <<-EOF
font2svg [option] ... romfile

-h, --help:
show help

--outfile filename, -o filename:
write output to filename

romfile: ROM dump file containing the font to convert

EOF
		exit
	when '--outfile'
		outfile = arg
	end
end

if ARGV.length != 1
	puts "Missing infile argument (try --help)"
	exit 0
end

infile = ARGV.shift

glyphs = Array[
	Array["&#x20;", "SPACE"],
	Array["&#x21;", "EXCLAMATION MARK"],
	Array["&#x22;", "QUOTATION MARK"],
	Array["&#x23;", "NUMBER SIGN"],
	Array["$", "DOLLAR SIGN"],
	Array["&#x25;", "PERCENT SIGN"],
	Array["&#x26;", "AMPERSAND"],
	Array["&#x27;", "APOSTROPHE"],
	Array["(", "LEFT PARENTHESIS"],
	Array[")", "RIGHT PARENTHESIS"],
	Array["*", "ASTERISK"],
	Array["+", "PLUS SIGN"],
	Array[",", "COMMA"],
	Array["-", "HYPHEN-MINUS"],
	Array[".", "FULL STOP"],
	Array["/", "SOLIDUS"],
	Array["0", "DIGIT ZERO"],
	Array["1", "DIGIT ONE"],
	Array["2", "DIGIT TWO"],
	Array["3", "DIGIT THREE"],
	Array["4", "DIGIT FOUR"],
	Array["5", "DIGIT FIVE"],
	Array["6", "DIGIT SIX"],
	Array["7", "DIGIT SEVEN"],
	Array["8", "DIGIT EIGHT"],
	Array["9", "DIGIT NINE"],
	Array[":", "COLON"],
	Array[";", "SEMICOLON"],
	Array["&#x3c;", "LESS-THAN SIGN"],
	Array["=", "EQUALS SIGN"],
	Array["&#x3e;", "GREATER-THAN SIGN"],
	Array["?", "QUESTION MARK"],
	Array["@", "COMMERCIAL AT"],
	Array["A", "LATIN CAPITAL LETTER A"],
	Array["B", "LATIN CAPITAL LETTER B"],
	Array["C", "LATIN CAPITAL LETTER C"],
	Array["D", "LATIN CAPITAL LETTER D"],
	Array["E", "LATIN CAPITAL LETTER E"],
	Array["F", "LATIN CAPITAL LETTER F"],
	Array["G", "LATIN CAPITAL LETTER G"],
	Array["H", "LATIN CAPITAL LETTER H"],
	Array["I", "LATIN CAPITAL LETTER I"],
	Array["J", "LATIN CAPITAL LETTER J"],
	Array["K", "LATIN CAPITAL LETTER K"],
	Array["L", "LATIN CAPITAL LETTER L"],
	Array["M", "LATIN CAPITAL LETTER M"],
	Array["N", "LATIN CAPITAL LETTER N"],
	Array["O", "LATIN CAPITAL LETTER O"],
	Array["P", "LATIN CAPITAL LETTER P"],
	Array["Q", "LATIN CAPITAL LETTER Q"],
	Array["R", "LATIN CAPITAL LETTER R"],
	Array["S", "LATIN CAPITAL LETTER S"],
	Array["T", "LATIN CAPITAL LETTER T"],
	Array["U", "LATIN CAPITAL LETTER U"],
	Array["V", "LATIN CAPITAL LETTER V"],
	Array["W", "LATIN CAPITAL LETTER W"],
	Array["X", "LATIN CAPITAL LETTER X"],
	Array["Y", "LATIN CAPITAL LETTER Y"],
	Array["Z", "LATIN CAPITAL LETTER Z"],
	Array["[", "LEFT SQUARE BRACKET"],
	Array["&#xa3;", "POUND SIGN"],
	Array["]", "RIGHT SQUARE BRACKET"],
	Array["&#x2191;", "UPWARDS ARROW"],
	Array["&#x2190;", "LEFTWARDS ARROW"],
	Array["&#x2500;", "BOX DRAWINGS LIGHT HORIZONTAL"],
	Array["a", "LATIN SMALL LETTER A"],
	Array["b", "LATIN SMALL LETTER B"],
	Array["c", "LATIN SMALL LETTER C"],
	Array["d", "LATIN SMALL LETTER D"],
	Array["e", "LATIN SMALL LETTER E"],
	Array["f", "LATIN SMALL LETTER F"],
	Array["g", "LATIN SMALL LETTER G"],
	Array["h", "LATIN SMALL LETTER H"],
	Array["i", "LATIN SMALL LETTER I"],
	Array["j", "LATIN SMALL LETTER J"],
	Array["k", "LATIN SMALL LETTER K"],
	Array["l", "LATIN SMALL LETTER L"],
	Array["m", "LATIN SMALL LETTER M"],
	Array["n", "LATIN SMALL LETTER N"],
	Array["o", "LATIN SMALL LETTER O"],
	Array["p", "LATIN SMALL LETTER P"],
	Array["q", "LATIN SMALL LETTER Q"],
	Array["r", "LATIN SMALL LETTER R"],
	Array["s", "LATIN SMALL LETTER S"],
	Array["t", "LATIN SMALL LETTER T"],
	Array["u", "LATIN SMALL LETTER U"],
	Array["v", "LATIN SMALL LETTER V"],
	Array["w", "LATIN SMALL LETTER W"],
	Array["x", "LATIN SMALL LETTER X"],
	Array["y", "LATIN SMALL LETTER Y"],
	Array["z", "LATIN SMALL LETTER Z"],
	Array["&#x2502;", "BOX DRAWINGS LIGHT VERTICAL"],
	Array["_", "LOW LINE"],
	Array["&#x25b3;", "WHITE UP-POINTING TRIANGLE"],
	Array["&#x3a0;", "GREEK CAPITAL LETTER PI"],
	Array["&#x25fb;&#xfe0e;", "WHITE MEDIUM SQUARE"]
]


if file = File.open(infile)
	if svgfile = File.new(outfile, "w")
		svgfile.write("<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>\n")
		svgfile.write("<svg width=\"100%\" height=\"100%\" version=\"1.1\" xmlns = \'http://www.w3.org/2000/svg\'>\n")
		svgfile.write("\t<defs>\n")
		svgfile.write("\t\t<font id=\"Font1520\" horiz-adv-x=\"8\">\n")
		svgfile.write("\t\t\t<font-face font-family=\"CBM\" font-weight=\"light\" font-style=\"normal\" units-per-em=\"8\" cap-height=\"6\" x-height=\"4\" ascent=\"7\" descent=\"1\">\n")
		svgfile.write("\t\t\t\t<font-face-src>\n")
		svgfile.write("\t\t\t\t\t<font-face-name name=\"1520 Normal\"/>\n")
		svgfile.write("\t\t\t\t</font-face-src>\n")
		svgfile.write("\t\t\t</font-face>\n")
		svgfile.write("\t\t\t<missing-glyph>\n")
		svgfile.write("\t\t\t\t<path d=\"M0 0H7V7H0V0M1 2L2 1L4 1L5 2L5 3L4 4L3 4L3 5M3 6L3 7\"/>\n")
		svgfile.write("\t\t\t</missing-glyph>\n")

		file.getbyte	# skip the first byte

		for glyph in 0..95
			svgfile.write("\t\t\t<glyph unicode=\"" + glyphs[glyph][0] + "\">\n")
			svgfile.write("\t\t\t\t<!-- "+ glyphs[glyph][1] +" -->\n")
			pathstring = "\t\t\t\t<path d=\""
			while byte = file.getbyte
				x = (byte & 0b01110000) >> 4
				y = 7 - ((byte & 0b00001110) >> 1)
#				printf("Byte = %02X\t X = %02X\t Y = %02X\t P = %02X\n", byte, x, y, byte & 0b00000001)
				if byte & 0b00000001 > 0
					pathstring += "L"
				else
					pathstring += "M"
				end
				pathstring += x.to_s + " " + y.to_s

				if byte & 0b10000000 > 0	# last path component
#					pathstring += "\" style=\"fill: none; stroke: black; stroke-width: 1\"/>\n"
					pathstring += "\" style=\"fill: none;\"/>\n"
					svgfile.write(pathstring)
					svgfile.write("\t\t\t</glyph>\n")
					break
				end
			end
		end

		svgfile.write("\t\t</font>\n")
		svgfile.write("\t</defs>\n")
		svgfile.write("</svg>\n")
		svgfile.close
	end
	file.close
end


#
# Font format:
#
# %EXXXYYYP
# E - last command in list (1)
# X - x coordinate (0-7)
# Y - y coordinate (0-7)
# P - use pen (1), or just move (0)
#
