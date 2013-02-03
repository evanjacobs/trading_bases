require "test/unit"
 
class TestParser < Test::Unit::TestCase
    include ParsingFunctions

    def test_combinators
        assert(always().call(["test"]) == res(["test"], nil), "always")
        assert(never().call(["test"]) == nil, "never")

        more = "More"
        assert(str("Test").call(["Test", more]) == res([more], "Test"), "str")
        assert(regex(/^[A-Z]+$/).call(["Test"]) == nil, "regex fail")
        assert(regex(/^[A-Z]+$/).call(["TEST", more]) == res([more], "TEST"), "regex pass")

        pa = str("a")
        pb = str("b")
        assert(seq(pa, pb).call(["a", "b", more]) == res([more], ["a", "b"]), "seq pass")
        assert(seq(pa, pb).call(["a", "bad", more]) == nil, "seq fail")
        assert(seq(pa, pb).call(["aaa", "b", more]) == nil, "seq fail")

        assert(alt(pa, pb).call(["a", more]) == res([more], "a"), "alt pass")
        assert(alt(pa, pb).call(["b", more]) == res([more], "b"), "alt pass")
        assert(alt(pa, pb).call(["c", more]) == nil, "alt fail")

        assert(val(pa, 1).call(["a", more]) == res([more], 1), "val pass")
        assert(val(pa, 1).call(["b", more]) == nil, "val fail")

        assert(map(val(pa, 1), lambda {|x| x + 1 }).call(["a", more]) == res([more], 2), "map pass")
        assert(map(val(pa, 1), lambda {|x| x + 1 }).call(["b", more]) == nil, "map fail")

        pc = str("c")
        assert(altm([pa, pb, pc]).call(["c", more]) == res([more], "c"), "altm pass")
        assert(altm([pa, pb, pc]).call(["d", more]) == nil, "altm fail")
        assert(seqm([pa, pb, pc]).call(["a", "b", "c", more]) == res([more], ["a", "b", "c"]), "seqm pass")
        assert(seqm([pa, pb, pc]).call(["a", "b", more]) == nil, "seqm fail")

        assert(opt(pa).call(["a", more]) == res([more], "a"), "opt pass")
        assert(opt(pa).call(["b", more]) == res(["b", more], nil), "opt null")

        assert(idx(seqm([pa, pb, pc]), 2).call(["a", "b", "c", more]) == res([more], "c"), "idx pass")

        assert(star(pa).call([more]) == res([more], []), "star none")
        assert(star(pa).call(["a", more]) == res([more], ["a"]), "star one")
        assert(star(pa).call(["a", "a", more]) == res([more], ["a", "a"]), "star multiple")

        assert(plus(pa).call([more]) == nil, "plus fail")
        assert(plus(pa).call(["a", more]) == res([more], ["a"]), "plus fail")
        assert(plus(pa).call(["a", "a", more]) == res([more], ["a", "a"]), "plus multiple")
    end

    def test_parser
        assert(parse_player.call(["Derek", "Jeter"]) == res([], "Derek Jeter"), "player pass")
        assert(parse_player.call(["Derek", "grounds"]) == nil, "player fail")

        assert(
            parse_out().call(
                tokenize("grounds out sharply, first baseman Mark Teixeira to pitcher Freddy Garcia")
            ) == res([], {:type => OutTypes::FIELDED, :position => Positions::FIRSTBASE, :player => "Mark Teixeira" }), 
            "grounds out sharply, first baseman Mark Teixeira to pitcher Freddy Garcia"
        )

        assert_equal(
            parse_out().call(
                tokenize("strikes out swinging")
            ),
            res([], {:type => OutTypes::STRIKEOUT}),
            "strikes out swinging"
        )

        assert_equal(
            parse_out().call(
                tokenize("called out on strikes")
            ),
            res([], {:type => OutTypes::STRIKEOUT}),
            "called out on strikes"
        )

        assert_equal(
            parse_out().call(tokenize("grounds into a double play, pitcher Felix Hernandez to shortstop Brendan Ryan to first baseman Mike Carp.")),
            res([], {:type => OutTypes::FIELDED, :position => Positions::PITCHER, :player => "Felix Hernandez"}),
            "grounds into a double play, pitcher Felix Hernandez to shortstop Brendan Ryan to first baseman Mike Carp."
        )

        assert_equal(
            {:type => AtBatResult::OUT, :detail => {:type => OutTypes::FIELDED, :position => Positions::SECONDBASE, :player => "Dustin Ackley"}},
            parse_atbat("Derek Jeter grounds out, second baseman Dustin Ackley to first baseman Mike Carp."),
            "Derek Jeter grounds out, second baseman Dustin Ackley to first baseman Mike Carp."
        )

        assert_equal(
            {:type => AtBatResult::HBP, :detail => nil},
            parse_atbat("Derek Jeter hit by pitch."),
            "Derek Jeter hit by pitch."
        )
    end
end
