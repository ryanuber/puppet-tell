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

require 'puppet/provider'
require 'net/smtp'

Puppet::Type.type(:tell).provide :mail do
  defaultfor :kernel => 'Linux'

  Puppet::Type.type(:tell).newparam(:from) do
    desc = "The 'from:' address of the message. Defaults to 'puppet@[your-fqdn]'.
      If you specify just a name (no @domain.com part), the message will be sent
      as '[name]@[your-fqdn]'."
    defaultto 'puppet'
    validate do |value|
      unless /^[a-zA-Z0-9_\.]+(@[a-zA-Z0-9\-_\.]+)?$/.match(value)
        fail Puppet::Error, "Invalid mail recipient address '#{value}'"
      end
    end
    munge do |value|
      value += "@#{Facter::fqdn}" unless value.include? '@'
      value
    end
  end

  Puppet::Type.type(:tell).newparam(:subject) do
    desc = "The message subject"
  end

  def tell
    subject = (@resource[:subject] == nil ? "Puppet: #{@resource.to_s}" : @resource[:subject])
    message = "From: #{@resource[:from]}\r\n" +
              "To: #{@resource[:dest]}\r\n" +
              "Subject: #{subject}\r\n\r\n" +
              @resource.encode(@resource.get_triggers, @resource[:format])
    Net::SMTP.start('localhost') do |smtp|
      Puppet.debug("Attempting to send message to #{@resource[:dest]} using SMTP relay localhost")
      smtp.send_message message, @resource[:from], @resource[:dest]
    end
  end

end
