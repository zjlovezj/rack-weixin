# -*- encoding : utf-8 -*-
require 'multi_json'
require 'nestful'

module Weixin

  class Menu
    def initialize(api, key)
      @api = api
      @key = key
      
      @access_token = nil
      @expired_at   = Time.now
      @endpoint     = 'https://api.weixin.qq.com/cgi-bin'
    end

    def access_token
      if Time.now >= @expired_at
        authenticate
      end
      @access_token
    end

    def gw_path(method)
      "/menu/#{method}?access_token=#{access_token}"
    end

    def gw_url(method)
      "#{@endpoint}" + gw_path(method)
    end

    def get
      request = Nestful.get gw_url('get') rescue nil
      MultiJson.load(request.body) unless request.nil?
    end

    def add(menu)
      p "menu: hash is #{hash.inspect}"
      p "menu: json is #{MultiJson.dump(menu)}"
      request = Nestful::Connection.new(gw_url('create')).post(gw_path('create'), MultiJson.dump(menu)) rescue nil
      unless request.nil?
        p "menu: request is not nil"
        p "menu: errocode is #{MultiJson.load(request.body)['errcode']}"
        errcode = MultiJson.load(request.body)['errcode']
        return true if errcode == 0
      end
      false
    end

    def authenticate
      url = "#{@endpoint}/token"
      p "menu: going to authenticate"
      request = Nestful.get url, { grant_type: 'client_credential', appid: @api, secret: @key } rescue nil
      unless request.nil?
        auth = MultiJson.load(request.body)
        unless auth.has_key?('errcode')
          @access_token = auth['access_token']
          @expired_at   = Time.now + auth['expires_in'].to_i
        end
        p "menu: access_token is #{@access_token}"
        @access_token
      end
    end
  end

end