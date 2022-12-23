#!/usr/local/bin/julia
using ArgParse

function main(args)
    # Argument parsing
    settings = ArgParseSettings()

    add_arg_group!(settings, "I/O option:")
    @add_arg_table! settings begin
        "-i"
        help = "input"
        # arg_type = String
        # action = :store_arg
        # required = true
        "-o"
        help = "output"
        # arg_type = String
        # action = :store_arg
        # required = true
    end

    args = parse_args(args, settings)

    # Main body
end

main(ARGS)
