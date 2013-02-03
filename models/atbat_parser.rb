
module AtBatTypes
    module AtBatResult
        HIT = 1
        OUT = 2
        WALK = 3
        HBP = 4
    end

    module OutTypes
        FIELDED = 1
        STRIKEOUT = 2
    end

    module HitTypes
        SINGLE = 1
        DOUBLE = 2
        TRIPLE = 3
        HOMERUN = 4
    end

    module Positions
        PITCHER = 1
        CATCHER = 2
        FIRSTBASE = 3
        SECONDBASE = 4
        THIRDBASE = 5
        SHORTSTOP = 6
        LEFTFIELD = 7
        CENTERFIELD = 8
        RIGHTFIELD = 9
    end
end

module ParsingFunctions
    include AtBatTypes

    Struct.new("ParseResult", :tokens, :result)

    def noisy()
        return false
    end

    def parse_atbat(text)
        tokens = tokenize(text)

        player = parse_player()

        play = idx(seqm([
            player,
            altm([
                map(parse_out(), lambda {|d| { :type => AtBatResult::OUT, :detail => d}}),
                map(parse_walk(), lambda {|d| { :type => AtBatResult::WALK, :detail => d}}),
                map(parse_hbp(), lambda {|d| { :type => AtBatResult::HBP, :detail => d}}),
                map(parse_hit(), lambda {|d| { :type => AtBatResult::HIT, :detail => d}}),
            ]),
        ]), 1)

        r = play.call(tokens)
        if r == nil
            if noisy
                puts "PARSING FAILED: " + text
            end
            return nil
        else
            if noisy
                if r.tokens.length > 0
                    puts "LEFTOVER: " + r.tokens.join(" ")
                end
            end
            return r.result
        end
    end

    def tokenize(text)
        return text.sub(/[,\.]/, "").split(/\s+/)
    end

    def parse_player()
        name = regex(/^[A-Z].*$/)
        return map(seqm([name, name]), lambda {|r| r[0] + " " + r[1]})
    end

    def parse_out()
        def parsify(a)
            altm(a.map {|s| val(seqm(s.split(" ").map {|p| str(p) }), s)})
        end

        player = parse_player()

        position_lookup = {
            "pitcher" => Positions::PITCHER, 
            "catcher" => Positions::CATCHER, 
            "first baseman" => Positions::FIRSTBASE, 
            "second baseman" => Positions::SECONDBASE, 
            "third baseman" => Positions::THIRDBASE, 
            "shortstop" => Positions::SHORTSTOP, 
            "right fielder" => Positions::LEFTFIELD, 
            "center fielder" => Positions::CENTERFIELD, 
            "left fielder" => Positions::RIGHTFIELD, 
        }
        positions = map(
            parsify(position_lookup.keys),
            lambda {|s| position_lookup[s]}
        )

        fielded_out_actions = parsify([
            "grounds into a double play",
            "grounds out sharply",
            "grounds out softly",
            "grounds out",
            "flies out sharply",
            "flies out softly",
            "flies out",
            "lines out sharply",
            "lines out softly",
            "lines out",
            "pops out sharply",
            "pops out softly",
            "pops out",
            "out on a sacrifice fly"
        ])

        fieldings = idx(
            seqm([
                fielded_out_actions,
                altm([
                    # "to first basemen Mark Teixiera"
                    map(
                        seqm([
                            str("to"),
                            positions,
                            parse_player
                        ]),
                        lambda {|r| {:type => OutTypes::FIELDED, :position => r[1], :player => r[2] }}
                    ),

                    # ", pitcher Felix Hernandez to shortstop Brendan Ryan to first baseman Mike Carp"
                    map(
                        seqm([
                            positions,
                            player,
                            plus(seqm([
                                str("to"),
                                positions,
                                player
                            ]))
                        ]),
                        lambda {|r| {:type => OutTypes::FIELDED, :position => r[0], :player => r[1]}}
                    )
                ])
            ]),
            1
        )

        # TODO: test third strike drop
        strikeout = val(
            parsify([
                "strikes out swinging",
                "called out on strikes"
            ]),
            {:type => OutTypes::STRIKEOUT}
        )

        return altm([
            fieldings,
            strikeout
        ])
    end

    def parse_hit()
        hit_lookup = {
            "singles" => HitTypes::SINGLE,
            "doubles" => HitTypes::DOUBLE,
            "triples" => HitTypes::TRIPLE,
            "homers" => HitTypes::HOMERUN
        }

        hits = map(
            parsify(hit_lookup.keys),
            lambda {|s| hit_lookup[s]}
        )

        return hits
    end

    def parse_walk()
        walk = altm([
            str("walks"),
            seqm([
                str("intentionally"),
                str("walks"),
                parse_player()
            ])
        ])

        return val(walk, nil)
    end

    def parse_hbp()
        return val(seqm([str("hit"), str("by"), str("pitch")]), nil)
    end

    def res(t, v)
        return Struct::ParseResult.new(t, v)
    end

    def str(string)
        lambda do |tokens|
            if tokens[0] == string
                return res(tokens[1..-1], tokens[0])
            else
                return nil
            end
        end
    end

    def always() 
        lambda do |tokens|
            return res(tokens, nil)
        end
    end

    def never() 
        lambda do |tokens|
            return nil
        end
    end

    def regex(expr)
        lambda do |tokens|
            if tokens[0].match(expr)
                return res(tokens[1..-1], tokens[0])
            else
                return nil
            end
        end
    end

    def seq(p1, p2)
        lambda do |tokens|
            r1 = p1.call(tokens)
            if r1 == nil
                return nil
            end

            r2 = p2.call(r1.tokens)
            if r2 == nil
                return nil
            end

            return res(r2.tokens, [r1.result, r2.result])
        end
    end

    def seqm(parsers)
        parsers.reverse.reduce(val(always(), [])) do |memo, obj|
            map(seq(obj, memo), lambda do |r|
                return [r[0]] + r[1]
            end)
        end
    end

    def alt(p1, p2)
        lambda do |tokens|
            r1 = p1.call(tokens)
            if r1 == nil
                return p2.call(tokens)
            else
                return r1
            end
        end
    end

    def altm(parsers)
        parsers.reverse.reduce {|memo, obj| alt(obj, memo) }
    end

    def opt(p)
        return alt(p, always())
    end

    def map(p, f)
        lambda do |tokens|
            r = p.call(tokens)
            if r != nil
                return res(r.tokens, f.call(r.result))
            else
                return nil
            end
        end
    end

    def val(p, v)
        return map(p, lambda {|x| v })
    end

    def idx(p, i)
        return map(p, lambda {|r| r[i] })
    end

    def star(p)
        lambda do |tokens|
            results = []
            r = p.call(tokens)
            while r != nil do
                tokens = r.tokens
                results.push(r.result)
                r = p.call(tokens)
            end

            return res(tokens, results)
        end
    end

    def plus(p)
        return map(seq(p, star(p)), lambda {|r| return [r[0]] + r[1] })
    end

    def log(name, p)
        lambda do |tokens|
            r = p.call(tokens)
            if r == nil
                puts name + ": failed on [" + tokens.join(", ") + "]\n"
            end
            return r
        end
    end
end

class AtBatParser
    include ParsingFunctions

    def parse(text)
        parse_atbat(text)
    end
end
