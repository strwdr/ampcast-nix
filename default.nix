{
  pkgs ? import <nixpkgs> { },
  lib ? pkgs.lib,
}:

let
  pname = "ampcast";
  version = "0.9.27";

  src = pkgs.fetchFromGitHub {
    owner = "rekkyrosso";
    repo = "ampcast";
    rev = "v${version}";
    hash = "sha256-n+kvqYUj5jsmUuVi1EckF9nSF2DJnMzbbSZxkySJDC0=";
  };

  electron = pkgs.electron;

  loopbackStub = pkgs.writeText "loopback-stub.js" ''
    import {ipcMain, session, desktopCapturer} from 'electron';

    export function initMain() {
        ipcMain.handle('enable-loopback-audio', () => {
            session.defaultSession.setDisplayMediaRequestHandler(async (_, callback) => {
                const sources = await desktopCapturer.getSources({types: ['screen']});
                callback({video: sources[0], audio: 'loopback'});
            });
        });
        ipcMain.handle('disable-loopback-audio', () => {
            session.defaultSession.setDisplayMediaRequestHandler(null);
        });
    }
  '';

  removedDeps = [
    "electron-audio-loopback"
    "electron-updater"
    "electron-log"
  ];

  appSrc = pkgs.runCommand "${pname}-app-src" { } ''
    cp -r ${src}/app $out
    chmod -R u+w $out

    rm='${builtins.toJSON removedDeps}'

    ${pkgs.jq}/bin/jq --argjson rm "$rm" '
      .dependencies |= with_entries(select(.key as $k | $rm | index($k) | not))
      | del(.devDependencies)
      | .desktopName = "ampcast.desktop"
    ' $out/package.json > $out/package.json.new
    mv $out/package.json.new $out/package.json

    ${pkgs.jq}/bin/jq --argjson rm "$rm" '
      ($rm | map("node_modules/" + .))       as $rmKeys     |
      ($rm | map("node_modules/" + . + "/")) as $rmPrefixes |
      .packages |= with_entries(select(
          (.value.dev != true)
          and (.key != "node_modules/electron")
          and ((.key | startswith("node_modules/electron/")) | not)
          and ((.key | startswith("node_modules/@electron/")) | not)
          and (.key as $k | ($rmKeys | index($k)) | not)
          and (.key as $k | $rmPrefixes | any(. as $p | $k | startswith($p)) | not)
        ))
      | .packages[""] |= del(.devDependencies)
      | .packages[""].dependencies |= with_entries(select(.key as $k | $rm | index($k) | not))
    ' $out/package-lock.json > $out/package-lock.json.new
    mv $out/package-lock.json.new $out/package-lock.json
  '';

  appDeps = pkgs.fetchNpmDeps {
    name = "${pname}-app-npm-deps-${version}";
    src = appSrc;
    hash = "sha256-1/Sj2UV9pYq6/G6D2luBD3N1XyKNP73FmjscgOKrcDc=";
  };

in
pkgs.buildNpmPackage rec {
  inherit pname version src;

  nodejs = pkgs.nodejs_24;
  npmDepsHash = "sha256-HXMGuA54GSbakKkP7xrSeSO5qTZ8TOYdUhQv7dI6HWs=";
  npmBuildScript = "build:electron";

  env.ELECTRON_SKIP_BINARY_DOWNLOAD = "1";

  nativeBuildInputs = with pkgs; [
    makeWrapper
    copyDesktopItems
  ];

  desktopItems = [
    (pkgs.makeDesktopItem {
      name = "ampcast";
      desktopName = "Ampcast";
      genericName = "Music Player";
      comment = "Music player for streaming services and personal media servers";
      exec = "ampcast %U";
      icon = "ampcast";
      categories = [ "Audio" "AudioVideo" ];
      startupWMClass = "ampcast";
      mimeTypes = [ "x-scheme-handler/ampcast" ];
    })
  ];

  postPatch = ''
    cp ${loopbackStub} app/src/loopback-stub.js
    substituteInPlace app/src/main.js \
      --replace-fail "from 'electron-audio-loopback'" "from './loopback-stub.js'" \
      --replace-fail "    components,
" "" \
      --replace-fail "[server.start(), components.whenReady()]" "[server.start()]" \
      --replace-fail "import electronUpdater from 'electron-updater';" "" \
      --replace-fail "import log from 'electron-log';" "" \
      --replace-fail "const {autoUpdater} = electronUpdater;" "" \
      --replace-fail "await checkForUpdatesAndNotify();" "" \
      --replace-fail "    app.quit();
}" "    app.exit(0);
}"

    substituteInPlace src/services/theme/fonts.ts \
      --replace-fail "    googleFont('Albert Sans'),
    {name: 'Arial', value: 'Arial,sans-serif'},
    googleFont('Bricolage Grotesque'),
    {name: 'Courier New', value: '\"Courier New\",Courier,monospace'},
    {name: 'Cursive', value: 'cursive'},
    googleFont('Fraunces'),
    {name: 'Georgia', value: 'Georgia,serif'},
    googleFont('Hind'),
    googleFont('Inconsolata'),
    googleFont('Inter'),
    googleFont('Lato'),
    googleFont('Lora'),
    {name: 'Monospace', value: 'monospace'},
    googleFont('Montserrat'),
    googleFont('Muli'),
    googleFont('Nunito Sans'),
    googleFont('Open Sans'),
    googleFont('Overpass'),
    googleFont('Oxygen'),
    googleFont('Poppins'),
    googleFont('Roboto'),
    googleFont('Space Grotesk'),
    {name: 'System UI', value: 'system-ui,sans-serif'},
    {name: 'Tahoma', value: 'Tahoma,Verdana,sans-serif'},
    {name: 'Times New Roman', value: '\"Times New Roman\",Times,serif'},
    googleFont('Ubuntu'),
    googleFont('Urbanist'),
    {name: 'Verdana', value: 'Verdana,sans-serif'},
];" "    googleFont('Albert Sans'),
    {name: 'Arial', value: 'Arial,sans-serif'},
    googleFont('Atkinson Hyperlegible'),
    googleFont('Audiowide'),
    googleFont('Bricolage Grotesque'),
    googleFont('Bungee'),
    googleFont('Caveat', 'cursive'),
    googleFont('Cinzel', 'serif'),
    {name: 'Courier New', value: '\"Courier New\",Courier,monospace'},
    {name: 'Cursive', value: 'cursive'},
    googleFont('Fira Code', 'monospace'),
    googleFont('Fraunces'),
    {name: 'Georgia', value: 'Georgia,serif'},
    googleFont('Hind'),
    googleFont('Honk'),
    googleFont('IBM Plex Mono', 'monospace'),
    googleFont('Inconsolata'),
    googleFont('Inter'),
    googleFont('JetBrains Mono', 'monospace'),
    googleFont('Jersey 10'),
    googleFont('Lato'),
    googleFont('Lobster'),
    googleFont('Lora'),
    googleFont('Major Mono Display', 'monospace'),
    googleFont('Merriweather', 'serif'),
    {name: 'Monospace', value: 'monospace'},
    googleFont('Montserrat'),
    googleFont('Muli'),
    googleFont('Nunito Sans'),
    googleFont('Open Sans'),
    googleFont('Orbitron'),
    googleFont('Overpass'),
    googleFont('Oxygen'),
    googleFont('Pacifico', 'cursive'),
    googleFont('Permanent Marker', 'cursive'),
    googleFont('Pixelify Sans'),
    googleFont('Playfair Display', 'serif'),
    googleFont('Poppins'),
    googleFont('Press Start 2P', 'monospace'),
    googleFont('Roboto'),
    googleFont('Share Tech Mono', 'monospace'),
    googleFont('Silkscreen', 'monospace'),
    googleFont('Source Code Pro', 'monospace'),
    googleFont('Space Grotesk'),
    googleFont('Space Mono', 'monospace'),
    {name: 'System UI', value: 'system-ui,sans-serif'},
    {name: 'Tahoma', value: 'Tahoma,Verdana,sans-serif'},
    {name: 'Times New Roman', value: '\"Times New Roman\",Times,serif'},
    googleFont('Ubuntu'),
    googleFont('Ubuntu Mono', 'monospace'),
    googleFont('Urbanist'),
    {name: 'Verdana', value: 'Verdana,sans-serif'},
    googleFont('Victor Mono', 'monospace'),
    googleFont('VT323', 'monospace'),
];"
  '';

  preBuild = ''
    install -m 644 ${appSrc}/package.json      app/package.json
    install -m 644 ${appSrc}/package-lock.json app/package-lock.json

    appCache=$(mktemp -d)
    cp -r ${appDeps}/. "$appCache"
    chmod -R u+w "$appCache"

    ( cd app && npm ci \
        --offline --omit=dev --ignore-scripts \
        --no-audit --no-fund --no-progress \
        --cache="$appCache" )
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/ampcast
    cp -r app/src app/www app/assets app/node_modules $out/share/ampcast/
    cp app/package.json $out/share/ampcast/

    for size in 16 32 64 128 256; do
      install -Dm644 \
        app/assets/icons/ampcast''${size}x''${size}.png \
        $out/share/icons/hicolor/''${size}x''${size}/apps/ampcast.png
    done

    runHook postInstall
  '';

  postInstall = ''
    makeWrapper ${electron}/bin/electron $out/bin/ampcast \
      --add-flags "$out/share/ampcast" \
      --add-flags "--ozone-platform-hint=auto" \
      --add-flags "--no-sandbox" \
      --add-flags "--class=ampcast" \
      --set NODE_ENV production
  '';

  meta = {
    description = "Music player for streaming services and personal media servers";
    homepage = "https://ampcast.app";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.linux;
    mainProgram = "ampcast";
  };
}
