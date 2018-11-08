require "./semantic_visitor.cr"

module Myst
  module TypeCheck
    class ProgramExpander < SemanticVisitor
      # A Hash of entries indicating files that have already been loaded. Entries
      # in this Hash should always be absolute paths to avoid ambiguity between
      # relative paths that resolve to the same file.
      property loaded_files = {} of String => Bool

      def visit(node : Require)
        path =
          case p = node.path
          when StringLiteral
            p.value
          else
            puts "Encountered `require` expression with non-constant path name. \
              The typechecker cannot resolve these expressions and may not be \
              able to complete checking successfully. Prefer using string literals \
              for all `require` expressions to avoid this possibility."
            return
          end

        working_dir =
          if loc = node.location
            File.dirname(loc.file)
          else
            raise "MYST BUG: Location information was not available to resolve the working directory for a `require` expression"
          end

        final_path = __resolve_path(p.value, working_dir)

        unless @loaded_files[final_path]?
          node.required_tree = ::Myst::Parser.for_file(final_path).parse
        end
        @loaded_files[final_path] = true
      end

      # TODO: In Myst itself, migrate path resolution to a static, publicly-
      # available API and use that here instead of duplicating the logic.
      private def load_dirs
        @load_dirs ||= begin
          paths = [] of String
          # Use any specified environment paths first.
          if env_paths = ENV["MYST_PATH"]?
            paths.concat(env_paths.split(':'))
          end
          paths.concat([
            # Then add the current working directory.
            Dir.current,
            # Finally, the directory where the executable is installed. This is
            # not _guaranteed_ on all systems, but support is good enough, so a
            # non-nil assertion is made.
            #
            # This assumes that the executable exists under a `bin/` folder. The
            # path added here will be the directory that contains `bin`.
            #
            # This is needed to locate the stdlib.
            File.dirname(File.dirname(File.join(Process.executable_path.not_nil!)))
          ])

          paths
        end.as(Array(String))
      end


      # Ensure that the given path resolves to a valid file and can be loaded.
      # The result of this method will always be a String to use directly in
      # a `File.read`.
      private def __resolve_path(path : String, working_dir) : String
        valid = false
        # Relative paths should be considered as-is. Absolute and bare paths
        # should consider all variants based on the current `load_dirs` that
        # are available.
        if is_relative?(path)
          path = File.expand_path(path, dir: working_dir)
          valid = validate_path(path)
        else
          load_dirs.find do |dir|
            expanded_path = File.expand_path(path, dir: dir)
            if valid = validate_path(expanded_path)
              path = expanded_path
              break
            end
          end
        end

        unless valid
          raise "failed to require '#{path}': file either doesn't exist or is not readable"
        end

        return path
      end

      # Return a boolean indicating whether the given path resolves to a real,
      # readable file.
      private def validate_path(full_path)
        File.exists?(full_path) && File.readable?(full_path)
      end

      private def is_relative?(path)
        path.starts_with?("./") || path.starts_with?("../")
      end
    end
  end
end
