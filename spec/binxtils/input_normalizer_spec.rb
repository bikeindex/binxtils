require "spec_helper"

RSpec.describe Binxtils::InputNormalizer do
  let(:subject) { described_class }
  describe "boolean" do
    context "1" do
      it "returns true" do
        expect(subject.boolean(1)).to eq true
        expect(subject.boolean(" 1")).to eq true
      end
    end
    context "string" do
      it "returns true" do
        expect(subject.boolean("something")).to eq true
        expect(subject.boolean(" Other Stuffff")).to eq true
      end
    end
    context "true" do
      it "returns true" do
        expect(subject.boolean(true)).to eq true
        expect(subject.boolean("true ")).to eq true
      end
    end
    context "nil" do
      it "returns false" do
        expect(subject.boolean).to eq false
        expect(subject.boolean(nil)).to eq false
      end
    end
    context "false" do
      it "returns false" do
        expect(subject.boolean(false)).to eq false
        expect(subject.boolean("false\n")).to eq false
      end
    end
  end

  describe "present_or_false?" do
    it "is true for false values" do
      expect(false.present?).to be_falsey # This is the problem!
      expect(subject.present_or_false?(false)).to eq true
      expect(subject.present_or_false?("false\n")).to eq true
      expect(subject.present_or_false?("0\n")).to eq true
      expect(subject.present_or_false?(0)).to eq true
    end
    it "is false for blank" do
      expect(subject.present_or_false?(nil)).to eq false
      expect(subject.present_or_false?("")).to eq false
      expect(subject.present_or_false?("   \n")).to eq false
    end
    it "is true for strings" do
      expect(subject.present_or_false?("something")).to eq true
      expect(subject.present_or_false?(true)).to eq true
      expect(subject.present_or_false?(3)).to eq true
    end
  end

  describe "string" do
    it "returns nil for blank" do
      expect(subject.string(nil)).to be_nil
      expect(subject.string("")).to be_nil
      expect(subject.string("   ")).to be_nil
    end
    it "strips and removes extra spaces" do
      expect(subject.string(" D  ")).to eq "D"
      expect(subject.string(" D HI \Z \nf ")).to eq "D HI \Z f"
    end
    it "removes null bytes" do
      expect(subject.string("D\u0000HI")).to eq "DHI"
      expect(subject.string(" D \u0000 HI ")).to eq "D HI"
    end
    it "casts non-string values" do
      expect(subject.string(123)).to eq "123"
      expect(subject.string(12.5)).to eq "12.5"
      expect(subject.string(:symbol)).to eq "symbol"
      expect(subject.string(false)).to be_nil # false is blank
    end
  end

  describe "regex_escape" do
    it "is nil for blank" do
      expect(subject.string(" ")).to be_nil
    end
    it "replaces" do
      expect(subject.regex_escape("(((..{?}")).to eq "........"
    end
  end

  describe "sanitize" do
    it "is empty string for nil" do
      expect(subject.sanitize).to eq ""
      expect(subject.sanitize(nil)).to eq ""
      expect(subject.sanitize("\n\n")).to eq ""
    end
    it "is string for boolean" do
      expect(subject.sanitize(true)).to eq "true"
      expect(subject.sanitize(false)).to eq "false"
      expect(subject.sanitize(" true")).to eq "true"
    end
    it "is strings for numbers" do
      expect(subject.sanitize(5)).to eq "5"
      expect(subject.sanitize(5_000)).to eq "5000"
      expect(subject.sanitize(" 5000 ")).to eq "5000"
      expect(subject.sanitize(5.000)).to eq "5.0"
      expect(subject.sanitize(BigDecimal(0))).to eq "0.0"
    end
    it "doesn't remove text but does remove whitespace" do
      expect(subject.sanitize("Some cool text ")).to eq "Some cool text"
      expect(subject.sanitize(" Some \tcool \ntext")).to eq "Some cool text"
    end
    it "strips html tags" do
      expect(subject.sanitize("<b>Hello</b> Plus other things</a>")).to eq "Hello Plus other things"
      expect(subject.sanitize("<div><b>Hello</b> Plus other </div>things</a>")).to eq "Hello Plus other things"
    end
    it "strips out script" do
      expect(subject.sanitize("<script>alert();</script>")).to eq ""
      expect(subject.sanitize("<b>Hello</b><script>alert()</script>")).to eq "Hello"
      expect(subject.sanitize('<b class="something">Hello</b><script>alert()</script>\\')).to eq "Hello\\"
    end
    it "returns bare ampersands" do
      expect(subject.sanitize("Bike & Ski")).to eq "Bike & Ski"
      expect(subject.sanitize("Bike &amp; Ski")).to eq "Bike & Ski"
    end
    it "leaves useful special characters" do
      expect(subject.sanitize("Bike ())( /// Ski ")).to eq "Bike ())( /// Ski"
      expect(subject.sanitize(' Bike [[] \\\ Ski ')).to eq 'Bike [[] \\\ Ski'
      expect(subject.sanitize("Surly's Cross-check bike")).to eq "Surly's Cross-check bike"
    end
    it "leaves accents" do
      expect(subject.sanitize("paké")).to eq "paké"
    end
    it "leaves emojis" do
      expect(subject.sanitize("🧹")).to eq "🧹"
    end
    it "removes angle brackets" do
      expect(subject.sanitize("Bike < Ski")).to eq "Bike &lt; Ski"
      expect(subject.sanitize("Bike &lt; Ski")).to eq "Bike &lt; Ski"
      expect(subject.sanitize("Bike > Ski")).to eq "Bike &gt; Ski"
      expect(subject.sanitize("Bike &gt; Ski")).to eq "Bike &gt; Ski"
      expect(subject.sanitize("Bike <> Ski")).to eq "Bike &lt;&gt; Ski"
      expect(subject.sanitize("Bike &lt;&gt; Ski")).to eq "Bike &lt;&gt; Ski"
    end
  end

  describe "plain_text" do
    context "blank" do
      it "is an empty string" do
        expect(subject.plain_text).to eq ""
        expect(subject.plain_text(nil)).to eq ""
        expect(subject.plain_text("")).to eq ""
        expect(subject.plain_text("  \n\n  ")).to eq ""
        expect(subject.plain_text("<div>&nbsp;</div>\n<div> </div>")).to eq ""
      end
    end

    context "with non-string values" do
      it "casts to a string" do
        expect(subject.plain_text(false)).to eq "false"
        expect(subject.plain_text(BigDecimal(0))).to eq "0.0"
      end
    end

    context "with an html body" do
      let(:body) { "<html><body style=\"padding:0;margin:0\"><div><p>It&#39;s 5 &lt; 6 &amp; &quot;broken&quot;</p></div></body></html>" }
      let(:target) { "It's 5 < 6 & \"broken\"" }

      it "is the text with the tags dropped and the entities unescaped" do
        expect(subject.plain_text(body)).to eq target
      end
    end

    context "with entities" do
      it "unescapes them, including the numeric ones" do
        expect(subject.plain_text("Bike &amp;amp; Ski")).to eq "Bike &amp; Ski"
        expect(subject.plain_text("It&#x27;s")).to eq "It's"
        expect(subject.plain_text("Hello&nbsp;&nbsp;world")).to eq "Hello  world"
      end
    end

    context "with html that isn't text" do
      it "drops the tags and their content" do
        expect(subject.plain_text("<script>alert('hi')</script>Text")).to eq "Text"
        expect(subject.plain_text("<head><style>p{color:red}</style></head><body>Text</body>")).to eq "Text"
      end
    end

    context "with an html email body" do
      let(:body) do
        "<div>Hi Seth,</div>\n<div>&nbsp;</div>\n<div>My bike was stolen &amp; I&#39;d like it back.</div>\n" \
          "<div>&nbsp;</div>\n<div>&nbsp;</div>\n<div>&nbsp;</div>\n<div>Thanks!</div>"
      end
      let(:target) { "Hi Seth,\n\nMy bike was stolen & I'd like it back.\n\nThanks!" }

      it "keeps the line breaks, collapsing runs of blank lines into one" do
        expect(subject.plain_text(body)).to eq target
      end
    end

    context "with indented lines" do
      it "strips each line and the result, keeping the whitespace inside a line" do
        expect(subject.plain_text("\n\n    line one  \n\t line two\t\n\n")).to eq "line one\nline two"
        expect(subject.plain_text("a\tb   c")).to eq "a\tb   c"
      end
    end

    context "with raw angle brackets" do
      it "leaves them decoded, unlike sanitize" do
        expect(subject.plain_text("5 <6 and 7> 6")).to eq "5 <6 and 7> 6"
        expect(subject.plain_text("Bike &lt; Ski")).to eq "Bike < Ski"
      end
    end
  end

  describe "normalize_whitespace" do
    context "blank" do
      it "is an empty string" do
        expect(subject.normalize_whitespace).to eq ""
        expect(subject.normalize_whitespace(nil)).to eq ""
        expect(subject.normalize_whitespace("  \n \n  ")).to eq ""
      end
    end

    context "with lines that are only a non-breaking space" do
      let(:body) { "Hi there\n \n \n \nThanks!" }
      let(:target) { "Hi there\n\nThanks!" }

      it "counts them as blank, collapsing the run into one" do
        expect(subject.normalize_whitespace(body)).to eq target
      end
    end

    context "with indented lines" do
      it "strips each line and the result, keeping the whitespace inside a line" do
        expect(subject.normalize_whitespace("\n\n    line one  \n\t line two\t\n\n")).to eq "line one\nline two"
        expect(subject.normalize_whitespace("a\tb   c")).to eq "a\tb   c"
      end
    end

    context "with html" do
      it "leaves it alone - this is whitespace only" do
        expect(subject.normalize_whitespace("<b>Hi</b>\n&amp;\n\n\n<i>bye</i>")).to eq "<b>Hi</b>\n&amp;\n\n<i>bye</i>"
      end
    end
  end
end
