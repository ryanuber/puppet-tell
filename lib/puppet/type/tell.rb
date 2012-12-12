# puppet-tell - Tell external people or things about changes to resources
#
# @author     Ryan Uber <ru@ryanuber.com>
# @link       https://github.com/ryanuber/puppet-tell
# @license    http://opensource.org/licenses/MIT
# @category   modules
# @package    tell
#
# MIT LICENSE
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

require 'puppet/type'

Puppet::Type.newtype(:tell) do
  @doc = "Tell external people or things about changes to resources. The
'tell' type allows you to alert external resources in a number of ways.
Most notably, the 'refreshonly' pattern, which is very similar to the
'exec' type's refreshonly, allows you to notify these external things only
when something happens. For example, a package gets updated. Someone or
something gets notified of the change. The simple web hooks implementation
makes automatic reporting a cinch - even if you are running masterless
puppet. Email alerts are more likely useful for smaller deployments with a
small number of system administrators. Stop grepping through log files
and running 'puppet apply' on the command line to find changes - Lemme
holler at ya!"

  def self.newcheck(name, options = {}, &block)
    @checks ||= {}

    check = newparam(name, options, &block)
    @checks[name] = check
  end

  def self.checks
    @checks.keys
  end

  newparam(:name) do
    desc "The name of the tell resource"
  end

  newparam(:refresh) do
    desc "Refresh this teller"
  end

  newcheck(:refreshonly) do
    desc "Whether or not to repeatedly call this resource. If true, this
      resource will only be executed when another resource tells it to
      do so. If set to false, it will execute at each run."
    newvalues(:true, :false)
    defaultto :true
    def check(value)
      value == :true ? false : true
    end
  end

  newparam(:dest) do
    desc "The recipient of the notification"
    validate do |value|
      if /^([a-zA-Z0-9\-\._]+)@([a-zA-Z0-9\-\._]+)$/.match(value)
        @resource.provider = :mail
      elsif /^http(s)?:\/\//.match(value)
        @resource.provider = :webhook
      else
        raise ArgumentError, "Unable to find suitable provider for destination '#{value}'"
      end
    end
  end

  newparam(:message) do
    desc "The message to send. This is free form text and is not content restricted."
  end

  newparam(:format) do
    desc "The encoding type to use for the resource object."
    newvalues(:json, :yaml)
    defaultto :yaml
  end

  newproperty(:returns, :array_matching => :all, :event => :told) do |property|
    defaultto '0'

    def retrieve
      if @resource.check_all_attributes
        return :not_told
      else
        return self.should
      end
    end

    def sync
      notice "Successfully told #{@resource[:dest]}" if provider.tell
      :told
    end
  end

  def refresh 
    if self.check_all_attributes(true)
      if self[:refresh]
        notice "Successfully told #{@resource[:dest]}" if provider.tell
        :told
      else
        self.property(:returns).sync
      end
    end     
  end

  def get_triggers
    triggers = []
    catalog.relationship_graph.each_edge do |r|
      triggers << r.source.to_resource.to_pson_data_hash if r.target == self
    end
    return triggers
  end

  def encode(data, format)
    format = format.to_s
    klass = format.upcase

    begin
        require format
    rescue
        fail Puppet::Error, "Failed to encode using '#{format}'"
    end

    return eval(klass).dump(data) if format == 'yaml'
    return eval(klass).pretty_generate(data) if format == 'json'
  end

  def check_all_attributes(refreshing = false)
    self.class.checks.each { |check| 
      next if refreshing and check == :refreshonly
      if @parameters.include?(check)
        val = @parameters[check].value
        val = [val] unless val.is_a? Array
        val.each do |value| 
          return false unless @parameters[check].check(value)
        end     
      end     
    }
    true
  end

end
