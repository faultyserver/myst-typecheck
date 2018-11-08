require "./typecheck.cr"

file_name = ARGV[0]

Myst::TypeCheck.typecheck(file_name)

puts "The program was successfully typechecked with no errors.".colorize(:green)
