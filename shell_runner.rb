require 'open4'
require 'shellwords'
require 'singleton'
require_relative 'result'


class ShellRunner
  include Singleton

  def initialize
    @bin = File.join(ENV['SHELL_DIR'].to_s, ENV['SHELL_NAME'] || 'MyShell')

    raise "Not an executable file: #{@bin}" unless File.executable?(@bin)

    @success_prompt = run.output.last
  end


  # Runs the user's shell with the given input lines as STDIN.
  def run(lines = [])
    result = Result.new

    # Annoyingly, ENV vars no longer seem to fully match between this and the
    # spawned process. This is my lazy fix: specify them all explicitly!
    env_vars = ENV.map{|k, v| "#{k}=#{Shellwords.shellescape v}" }.join(' ')
    cmd = "#{env_vars} #{@bin} 2>&1"

    status = Open4::popen4(cmd) do |pid, stdin, stdout, stderr|
      stdin.puts lines.join("\n")
      stdin.close

      result.output = stdout.read.lines.map do |line|
        line.chomp.gsub(/\e\[(\d+)(;\d+)?m/, '')
      end
    end

    result.input = lines
    result.success_prompt = @success_prompt
    result.return_code = status.exitstatus
    result
  end
end
