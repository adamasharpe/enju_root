module EnjuManifestationViewer
  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    def enju_manifestation_viewer
      include EnjuManifestationViewer::InstanceMethods
    end
  end

  module InstanceMethods
    def youtube_id
      if access_address
        url = URI.parse(access_address)
        if url.host =~ /youtube\.com$/ and url.path == "/watch"
          return CGI.parse(url.query)["v"][0]
        end
      end
    end

    def nicovideo_id
      if access_address
        url = URI.parse(access_address)
        if url.host =~ /nicovideo\.jp$/ and url.path =~ /^\/watch/
          return url.path.split("/")[2]
        end
      end
    end

    def flickr
      if access_address
        info = {}
        url = URI.parse(access_address)
        paths = url.path.split('/')
        if url.host =~ /^www\.flickr\.com$/ and paths[1] == 'photos' and paths[2]
          info[:user] = paths[2]
          if paths[3] == "sets"
            info[:set_id] = paths[4]
          end
        end
        return info
      end
    end

    # scribd_fuで定義
    #def scribd_id
    #  if access_address
    #    url = URI.parse(access_address)
    #    paths = url.path.split('/')
    #    if url.host =~ /^www\.scribd\.com$/ and paths[1] == 'doc' and paths[2]
    #      return paths[2]
    #    end
    #  end
    #end

  end
end
