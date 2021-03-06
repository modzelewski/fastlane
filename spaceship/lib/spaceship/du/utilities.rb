require 'fastimage'
require "English"

module Spaceship
  # Set of utility methods useful to work with media files
  module Utilities #:nodoc:
    # Identifies the content_type of a file based on its file name extension.
    # Supports all formats required by DU-UTC right now (video, images and json)
    # @param path (String) the path to the file
    def content_type(path)
      path = path.downcase
      return 'image/jpeg' if path.end_with?('.jpg')
      return 'image/png' if path.end_with?('.png')
      return 'application/json' if path.end_with?('.geojson')
      return 'video/quicktime' if path.end_with?('.mov')
      return 'video/mp4' if path.end_with?('.m4v')
      return 'video/mp4' if path.end_with?('.mp4')
      raise "Unknown content-type for file #{path}"
    end

    # Identifies the resolution of a video or an image.
    # Supports all video and images required by DU-UTC right now
    # @param path (String) the path to the file
    def resolution(path)
      return FastImage.size(path) if content_type(path).start_with?("image")
      return video_resolution(path) if content_type(path).start_with?("video")
      raise "Cannot find resolution of file #{path}"
    end

    # Is the video or image in portrait mode ?
    # Supports all video and images required by DU-UTC right now
    # @param path (String) the path to the file
    def portrait?(path)
      resolution = resolution(path)
      resolution[0] < resolution[1]
    end

    # Grabs a screenshot from the specified video at the specified timestamp using `ffmpeg`
    # @param video_path (String) the path to the video file
    # @param timestamp (String) the `ffmpeg` timestamp format (e.g. 00.00)
    # @param dimensions (Array) the dimension of the screenshot to generate
    # @return the path to the TempFile containing the generated screenshot
    def grab_video_preview(video_path, timestamp, dimensions)
      width, height = dimensions
      require 'tempfile'
      tmp = Tempfile.new(['video_preview', ".jpg"])
      file = tmp.path
      command = "ffmpeg -y -i \"#{video_path}\" -s #{width}x#{height} -ss \"#{timestamp}\" -vframes 1 \"#{file}\" 2>&1 >/dev/null"
      # puts "COMMAND: #{command}"
      `#{command}`
      raise "Failed to grab screenshot at #{timestamp} from #{video_path} (using #{command})" unless $CHILD_STATUS.to_i == 0
      tmp.path
    end

    # identifies the resolution of a video using `ffmpeg`
    # @param video_path (String) the path to the video file
    # @return [Array] the resolution of the video
    def video_resolution(video_path)
      command = "ffmpeg -i \"#{video_path}\" 2>&1"
      # puts "COMMAND: #{command}"
      output = `#{command}`
      # Note: ffmpeg exits with 1 if no output specified
      # raise "Failed to find video information from #{video_path} (using #{command})" unless $CHILD_STATUS.to_i == 0
      output = output.force_encoding("BINARY")
      video_infos = output.split("\n").select { |l| l =~ /Stream.*Video/ }
      raise "Unable to find Stream Video information from ffmpeg output of #{command}" if video_infos.count == 0
      video_info = video_infos[0]
      res = video_info.match(/.* ([0-9]+)x([0-9]+),.*/)
      raise "Unable to parse resolution information from #{video_info}" if res.count < 3
      [res[1].to_i, res[2].to_i]
    end

    module_function :content_type, :grab_video_preview, :portrait?, :resolution, :video_resolution
  end
end
