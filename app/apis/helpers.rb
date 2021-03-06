require 'will_paginate/array'

module APIHelpers

  # 认证管理员
  def staffer_authenticate!
    # 如果token不存在，则返回没有得到token
    raise APIErrors::NoGetAuthenticate unless request.headers["Authorization"].present?
    raise APIErrors::AuthenticateFail unless current_staffer
  end

  # 认证用户
  def authenticate!
    # 如果token不存在，则返回没有得到token
    raise APIErrors::NoGetAuthenticate unless request.headers["Authorization"].present?
    raise APIErrors::AuthenticateFail unless current_user
  end

  # 强制更新APP
  def force_update!
    return unless Rails.env.production?
    data = headers["X-Client-Version"]
    raise APIErrors::VersionOldError unless data.present?
    # TODO 暂时不对版本和设备进行区分限制
    #device, version = data.split("-")
    #raise APIErrors::VersionOldError if device == "iOS" && version < "2.0"
    #raise APIErrors::VersionOldError if device == "Android" && version < "2.0"
  end

  def verify_p2p_account!
    raise APIErrors::VeriftyFail, "还未开通理财宝账户" unless current_user.p2p_account_exists?
  end

  # 在接口执行之前进行统计工作
  def extend_callback
    # 记录用户活跃度
    current_user.try(:sign_user_active)
  rescue
    raise unless Rails.env.production?
  end

  # 设备的sn码
  def sn_code
    @header_sn_code ||= headers["X-Sn-Code"]
  end

  def current_staffer
    @current_staffer ||= begin
      header_token = request.headers["Authorization"]

      token = ApiStafferToken.where(access_token: header_token, sn_code: sn_code).first

      # 如果token存在并且没有过期
      if token && !token.expired?
        # 如果临近过期时间，推迟过期时间
        token.refresh_expires_at! if token.expires_at - Time.now <= 3.days
        token.staffer
      else
        nil
      end
    end
  end

  def current_user
    @current_user ||= begin
      header_token = request.headers["Authorization"]

      token = ApiToken.where(access_token: header_token, sn_code: sn_code).first

      # 如果token存在并且没有过期
      if token && !token.expired?
        # 如果临近过期时间，推迟过期时间
        token.refresh_expires_at! if token.expires_at - Time.now <= 3.days
        token.user
      else
        nil
      end
    end
  end

  # 对客户端提交的未正确进行UTF-8编码的数据进行编码
  def normalize_encode_params
    @env["rack.request.form_hash"] ||= {}
    encode_params_values params if request.form_data? && request.media_type == 'multipart/form-data'
  end

  # 迭代对 params 的 values 进行编码处理
  def encode_params_values(hash)
    return if hash.blank?
    hash.each do |k, v|
      if hash[k].is_a?(Hash)
        encode_params_values(hash[k])
      else
        hash[k].force_encoding(Encoding::UTF_8).encode! if hash[k].is_a?(String)
      end
    end
  end

  def paginate(objs)
    return objs unless objs.respond_to? :paginate
    total_entries = objs.count > 1000 ? 1000 : objs.count
    objs.paginate(page: params[:page] || 1, per_page: params[:per_page] || 10, total_entries: total_entries)
  end

  def present(data, options={})
    # 如果不是get请求并且能够reload，就执行reload保证数据同步更新
    data.reload if (!request.get?) && data.respond_to?(:reload)
    options.merge!(current_user: current_user) if current_user.present?

    is_paging = data.respond_to?(:total_pages)

    if is_paging
      super :per_page, data.per_page
      super :page, data.current_page
      super :total_pages, data.total_pages
      super :total_entries, data.total_entries
    end

    # 扩展n+1相关查询数据
    expand_data(data)

    is_paging ? super(:data, data, options) : super(data, options)
  end

  def expand_data(data)
    #User.expand_users(data) if [User::ActiveRecord_Relation, User::ActiveRecord_AssociationRelation].include? data.class
  end

  def dup_params
    params.dup.tap do |p|
      p.delete :format
      p.merge!(
        user_terminal_info: sn_code,
        user_terminal_ip: env['REMOTE_ADDR'] # request.remote_ip
      )
    end.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
  end

  # Etag
  def compare_etag(max_age=0, etag_key="", etag_match=params.map{|k,v| "#{k}:#{v}"}.join("-"))
    etag = etag_key + etag_match
    etag = "W/\"#{Digest::SHA1.hexdigest(etag)}\""

    header "Cache-control", "max-age=#{max_age}, private, must-revalidate"

    if request.headers["If-None-Match"] == etag
      error!("Not Modified", 304)
    end

    header "ETag", etag
  end

  def date_result_limit(data, begin_date, end_date, count)
    if begin_date.present? && count.present? && end_date.blank?
      data.first(count)
    elsif end_date.present? && count.present? && begin_date.blank?
      data.last(count)
    else
      data
    end
  end

  def p2p_get(method_name)
    p2p_data, p2p_headers = P2pService.send(method_name, current_user, dup_params)
    p2p_headers.except(*%w(Content-Type X-Frame-Options Allow Vary Server Date Transfer-Encoding Connection)).each{ |k,v| header k, v }
    p2p_data
  end

end
