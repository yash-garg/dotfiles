_: {
  programs.mpv.config = {
    # General
    profile = "gpu-hq";
    vo = "gpu-next";
    gpu-api = "vulkan";
    vd-lavc-dr = true;
    spirv-compiler = "auto";
    vulkan-async-compute = true;
    vulkan-async-transfer = true;
    vulkan-queue-count = 1;
    hwdev = "nvdec";
    video-sync = "display-resample";

    # Demuxer
    cache = true;
    cache-pause = true;
    cache-pause-wait = 1;
    demuxer-thread = "yes";
    demuxer-readahead-secs = "600";
    demuxer-max-bytes = "1000M";
    demuxer-max-back-bytes = "200M";
    demuxer-mkv-subtitle-preroll = true;

    # Resizers
    scale = "ewa_lanczos";
    dscale = "ewa_lanczos";
    cscale = "sinc";
    cscale-window = "blackman";
    cscale-radius = 3;

    # Deband
    deband = true;
    deband-iterations = 4;
    deband-threshold = 48;
    deband-range = 18;
    deband-grain = 32;

    # Audio
    volume = 80;
    volume-max = 200;
    audio-file-auto = "fuzzy";
    audio-pitch-correction = true;

    # Subtitles
    sub-ass-vsfilter-blur-compat = true;
    stretch-image-subs-to-screen = true;
    sub-fix-timing = true;
    sub-font = "Cabin";
    sub-font-size = 20;
    sub-border-size = 2;
    sub-auto = "fuzzy";
    sub-bold = true;
    sub-scale = 1;

    # Window
    osc = false;
    osd-bar = false;
    border = false;
    osd-font = "IosevkaTerm Nerd Font Mono";
    osd-font-size = 16;
    title = "\${media-title} [\${time-pos}\${!duration==0: / \${duration}}]";
    force-window-position = true;
    autofit-larger = "100%x85%";
    cursor-autohide = 100;
    force-window = true;
    keep-open = true;

    # Track Selection
    slang = "en,eng";
    alang = "en,eng,ja,jp,jpn";

    # Screenshot
    screenshot-format = "png";
    screenshot-high-bit-depth = false;
    screenshot-tag-colorspace = true;
    screenshot-png-compression = 9;
    screenshot-directory = "~/Pictures/Screenshots";
    screenshot-template = "mpvshot-%03n %tHh%tMm%tSs";

    # Streaming
    hls-bitrate = "max";
    ytdl-format = "bestvideo[height<=?1440]+bestaudio/bestvideo+bestaudio/best";
    ytdl-raw-options = "ignore-errors=";
    load-unsafe-playlists = true;

    glsl-shaders = "~~/shaders/FSRCNNX_x2_8-0-4-1.glsl:~~/shaders/FSRCNNX_x2_16-0-4-1.glsl:~~/shaders/SSimDownscaler.glsl:~~/shaders/KrigBilateral.glsl";
  };
}
