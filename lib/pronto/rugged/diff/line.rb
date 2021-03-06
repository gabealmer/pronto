module Rugged
  class Diff
    class Line
      def patch
        hunk.owner
      end

      def position
        hunk_index = patch.hunks.find_index { |h| h.header == hunk.header }
        line_index = patch.lines.find_index(self)

        line_index + hunk_index + 1
      end

      def commit
        @commit ||= begin
          repo.lookup(commit_sha) if commit_sha
        end
      end

      def commit_sha
        @commit_sha ||= begin
          blameline.commit.id if blameline
        end
      end

      def commit_line
        @commit_line ||= begin
          diff = commit.show
          patches = diff ? diff.patches : []
          commit_patch = patches.find do |p|
            patch.new_file_full_path == p.new_file_full_path
          end

          lines = commit_patch ? commit_patch.lines : []
          result = lines.find { |l| blameline.lineno == l.new_lineno }

          result || self # no commit_line means that it was just added
        end
      end

      def ==(other)
        content == other.content &&
          line_origin == other.line_origin &&
          old_lineno == other.old_lineno &&
          new_lineno == other.new_lineno
      end

      private

      def repo
        patch.diff.tree.repo
      end

      def blameline
        @blameline ||= begin
          blamelines = repo.blame(patch.new_file_full_path).lines
          blamelines.find { |line| line.lineno == new_lineno }
        end
      end
    end
  end
end
