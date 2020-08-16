require 'net/http'
require 'openssl'
require 'digest'
require 'json'
require 'rexml/document'
include REXML

class FritzAHA
  
  def initialize(fblogin, fbpasswd, fburl, sidfile)
    @fblogin  = fblogin
    @fbpasswd = fbpasswd
    @fburl    = fburl
    @sidfile  = sidfile
    @sid      = nil
    @debug    = false
  end

  def login
    if File.exists?(@sidfile)
      @sid = File.open(@sidfile,'r').gets.chomp
      STDERR.puts "old sid=#{sid}" if @debug
    else
      _login
    end
  end

  def debug(debug)
    @debug = debug
  end

  def sid
    @sid
  end

  def list
    _cmd('getswitchlist', nil)
  end

  def cmd(cmd, ain)
    _cmd(cmd, ain)
  end

  private

  def _debug_response(func, response)
    STDERR.puts "#{func} - #{response.code}" if @debug
    STDERR.puts "#{func} - #{response.msg}" if @debug
  end

  def _cmd(cmd,ain)
    if nil == @sid
       raise "no session, forgot to execute login?"
    end

    uristr = "#{@fburl}/webservices/homeautoswitch.lua?switchcmd=#{cmd}&sid=#{@sid}"
    uristr += "&ain=#{ain}" if nil != ain
    uri = URI(uristr)

    Net::HTTP.start(uri.host, uri.port, :use_ssl => true, :verify_mode => OpenSSL::SSL::VERIFY_NONE) do |http|
      request = Net::HTTP::Get.new uri
      response = http.request request
      if response.code != "200"
         _debug_response('_cmd', response)
         if response.code == "403"
           _login
           return _cmd(cmd, ain)
         else
           return [ response.code, response.msg ]
         end
      end
      return response.body
    end    
  end

  def _login
    uri = URI("#{@fburl}/login_sid.lua")
    @sid = challenge = nil
    Net::HTTP.start(uri.host, uri.port, :use_ssl => true, :verify_mode => OpenSSL::SSL::VERIFY_NONE) do |http|
      request = Net::HTTP::Get.new uri
      response = http.request request
      _debug_response('_login(init)', response)
      doc  = Document.new(response.body)
      @sid = XPath.first(doc, '//SID').text
      challenge=XPath.first(doc, '//Challenge').text
    end

    STDERR.puts "got sid=#{sid}, challenge=#{challenge}" if @debug

    if @sid == '0000000000000000'
      # create new sid only in case it has the value above
      md5=Digest::MD5.hexdigest("#{challenge}-#{@fbpasswd}".encode(Encoding::UTF_16LE))
      response="#{challenge}-#{md5}"

      STDERR.puts "response=#{response}" if @debug

      Net::HTTP.start(uri.host, uri.port, :use_ssl => true, :verify_mode => OpenSSL::SSL::VERIFY_NONE) do |http|
        request = Net::HTTP::Post.new uri
        request.set_form_data('response' => response, 'page' => '', 'username' => @fblogin)
        response = http.request request
        _debug_response('_login(getsid)', response)
        doc  = Document.new(response.body)
        @sid = XPath.first(doc, '//SID').text
        raise "unable to get a valid session; wrong login and/or password?" if @sid == '0000000000000000'
      end

      STDERR.puts "saving new sid=#{sid}" if @debug
      File.open(@sidfile,'w').puts(@sid)

    end
  end
end
