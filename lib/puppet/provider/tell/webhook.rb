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
require 'net/http'

Puppet::Type.type(:tell).provide :webhook do

  Puppet::Type.type(:tell).newparam(:get) do
    desc = "Name of the GET parameter to occupy."
  end

  Puppet::Type.type(:tell).newparam(:post) do
    desc = "Name of the POST parameter to occupy in the POST body."
  end

  def tell
    uri = URI.parse(@resource[:dest])
    uri.path = '/' unless uri.path != ''
    if @resource[:post] != nil
      Puppet.debug("Performing HTTP POST: #{uri.to_s}")
      request = Net::HTTP::Post.new(uri.path)
      request.set_form_data({@resource[:post] => @resource.encode(@resource.get_triggers, @resource[:format])})
    else
      if @resource[:get] != nil
        uri.query = URI.escape("#{@resource[:get]}=#{@resource.encode(@resource.get_triggers, @resource[:format])}")
      end
      Puppet.debug("Performing HTTP GET: #{uri.to_s}")
      request = Net::HTTP::Get.new(uri.to_s)
    end
    response = Net::HTTP.start(uri.host, uri.port) {|http| http.request(request) }
    fail Puppet::Error, "Web hook at '#{@resource[:dest]}' returned #{response.code}, expected 200" unless response.code == "200"
    Puppet.debug("Received response code #{response.code} during request to #{uri.to_s}")
  end

end
