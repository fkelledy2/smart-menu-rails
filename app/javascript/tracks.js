export function initTracks() {
//        window.onSpotifyWebPlaybackSDKReady = () => {
//            const token = $('#spotifyAccessToken').text();
//            const player = new Spotify.Player({
//                name: 'Mellow Menu :: Jukebox',
//                getOAuthToken: cb => { cb(token); },
//                volume: 0.75
//            });
//
//            // Ready
//            player.addListener('ready', ({ device_id }) => {
//                if( document.getElementById('togglePlay') != null ) {
//                    console.log('Ready with Device ID', device_id);
//                    document.getElementById("togglePlay").disabled = false;
//                    document.getElementById("previousTrack").disabled = false;
//                    document.getElementById("nextTrack").disabled = false;
//                    $('#spotifyConnect').addClass('btn-success').removeClass('btn-dark');
//                    $('#togglePlay').addClass('btn-success').removeClass('btn-dark');
//                    $('#previousTrack').addClass('btn-success').removeClass('btn-dark');
//                    $('#nextTrack').addClass('btn-success').removeClass('btn-dark');
//                }
//            });
//
//            // Not Ready
//            player.addListener('not_ready', ({ device_id }) => {
//                if( document.getElementById('togglePlay') != null ) {
//                    console.log('Device ID has gone offline', device_id);
//                    document.getElementById("togglePlay").disabled = true;
//                    document.getElementById("previousTrack").disabled = true;
//                    document.getElementById("nextTrack").disabled = true;
//                    $('#spotifyConnect').addClass('btn-dark').removeClass('btn-success');
//                    $('#togglePlay').addClass('btn-dark').removeClass('btn-success');
//                    $('#previousTrack').addClass('btn-dark').removeClass('btn-success');
//                    $('#nextTrack').addClass('btn-dark').removeClass('btn-success');
//                }
//            });
//
//            player.addListener('initialization_error', ({ message }) => {
//                if( document.getElementById('togglePlay') != null ) {
//                    console.error(message);
//                    document.getElementById("togglePlay").disabled = true;
//                    document.getElementById("previousTrack").disabled = true;
//                    document.getElementById("nextTrack").disabled = true;
//                }
//            });
//
//            player.addListener('authentication_error', ({ message }) => {
//                if( document.getElementById('togglePlay') != null ) {
//                    console.error(message);
//                    document.getElementById("togglePlay").disabled = true;
//                    document.getElementById("previousTrack").disabled = true;
//                    document.getElementById("nextTrack").disabled = true;
//                }
//            });
//
//            player.addListener('account_error', ({ message }) => {
//                if( document.getElementById('togglePlay') != null ) {
//                    console.error(message);
//                    document.getElementById("togglePlay").disabled = true;
//                    document.getElementById("previousTrack").disabled = true;
//                    document.getElementById("nextTrack").disabled = true;
//                }
//            });
//            player.addListener('player_state_changed', ({
//              position,
//              duration,
//              track_window: { current_track }
//            }) => {
//              console.log('Currently Playing', current_track);
//              console.log('Position in Song', position);
//              console.log('Duration of Song', duration);
//              console.log( 'searching for: '+current_track.name );
//              console.log( cleanString(current_track.name));
//              document.getElementById(cleanString(current_track.name)).scrollIntoView({ behavior: 'smooth' });
//            });
//
//            function cleanString(name) {
//                return name.replace(/\s/g, '').replace(/[^\w\s]/g, '');
//            }
//            if( document.getElementById('togglePlay') != null ) {
//                document.getElementById('togglePlay').onclick = function() {
//                  player.togglePlay();
//                };
//            }
//
//            if( document.getElementById('nextTrack') != null ) {
//                document.getElementById('nextTrack').onclick = function() {
//                  player.nextTrack();
//                };
//            }
//            if( document.getElementById('previousTrack') != null ) {
//                document.getElementById('previousTrack').onclick = function() {
//                  player.previousTrack();
//                };
//            }
//            player.connect();
//        }

    if ($("#restaurantTabs").is(':visible')) {

        function status(cell, formatterParams){
            return cell.getRow().getData("data").status.toUpperCase();
        }
        function link(cell, formatterParams){
            var id = cell.getValue();
            var name = cell.getRow();
            var rowData = cell.getRow().getData("data").externalid;
            return "<a class='link-dark' href='/tracks/"+id+"/edit'>"+rowData+"</a>";
        }
        const restaurantId = document.getElementById('restaurant-tracks-table').getAttribute('data-bs-restaurant_id');
        var restaurantTracksTable = new Tabulator("#restaurant-tracks-table", {
          height:"400px",
          dataLoader: false,
          responsiveLayout:true,
          layout:"fitData",
          ajaxURL: '/restaurants/'+restaurantId+'/tracks.json',
          initialSort:[
            {column:"sequence", dir:"asc"},
          ],
          movableRows:true,
          columns: [
          { rowHandle:true, formatter:"handle", vertAlign:"top", headerSort:false, frozen:true, responsive:0, width:30, minWidth:30 },
          { title:"", field:"sequence", visible:false, formatter:"rownum", responsive:5, hozAlign:"right", headerHozAlign:"right", headerSort:false },
          { title:"Sequence", field:"sequence", sorter:"number", visible: false, responsive:0, hozAlign:"left"},
          { title:"Name", field:"name", responsive:0, hozAlign:"left"},
          { title:"Artist", field:"artist", responsive:3, hozAlign:"left"},
          { title:"Album", field:"description", responsive:4, hozAlign:"left"},
          ],
          locale:true,
          langs:{
            "it":{
                "columns":{
                    "artist":"Artist",
                    "album":"Album",
                    "name":"Nome",
                    "image":"Image",
                    "status":"Stato",
                }
            },
            "en":{
                "columns":{
                    "artist":"Artist",
                    "album":"Album",
                    "name":"Name",
                    "image":"Image",
                    "status":"Status",
                }
            }
          }
        });

        window.onSpotifyWebPlaybackSDKReady = () => {
            const token = $('#spotifyAccessToken').text();
            const player = new Spotify.Player({
                name: 'Mellow Menu :: Jukebox (admin)',
                getOAuthToken: cb => { cb(token); },
                volume: 0.75
            });

            // Ready
            player.addListener('ready', ({ device_id }) => {
                if( document.getElementById('togglePlay') != null ) {
                    console.log('Ready with Device ID', device_id);
                    document.getElementById("togglePlay").disabled = false;
                    document.getElementById("previousTrack").disabled = false;
                    document.getElementById("nextTrack").disabled = false;
                    $('#spotifyConnect').addClass('btn-success').removeClass('btn-dark');
                    $('#togglePlay').addClass('btn-success').removeClass('btn-dark');
                    $('#previousTrack').addClass('btn-success').removeClass('btn-dark');
                    $('#nextTrack').addClass('btn-success').removeClass('btn-dark');
                }
            });

            // Not Ready
            player.addListener('not_ready', ({ device_id }) => {
                if( document.getElementById('togglePlay') != null ) {
                    console.log('Device ID has gone offline', device_id);
                    document.getElementById("togglePlay").disabled = true;
                    document.getElementById("previousTrack").disabled = true;
                    document.getElementById("nextTrack").disabled = true;
                    $('#spotifyConnect').addClass('btn-dark').removeClass('btn-success');
                    $('#togglePlay').addClass('btn-dark').removeClass('btn-success');
                    $('#previousTrack').addClass('btn-dark').removeClass('btn-success');
                    $('#nextTrack').addClass('btn-dark').removeClass('btn-success');
                }
            });

            player.addListener('initialization_error', ({ message }) => {
                if( document.getElementById('togglePlay') != null ) {
                    console.error(message);
                    document.getElementById("togglePlay").disabled = true;
                    document.getElementById("previousTrack").disabled = true;
                    document.getElementById("nextTrack").disabled = true;
                }
            });

            player.addListener('authentication_error', ({ message }) => {
                if( document.getElementById('togglePlay') != null ) {
                    console.error(message);
                    document.getElementById("togglePlay").disabled = true;
                    document.getElementById("previousTrack").disabled = true;
                    document.getElementById("nextTrack").disabled = true;
                }
            });

            player.addListener('account_error', ({ message }) => {
                if( document.getElementById('togglePlay') != null ) {
                    console.error(message);
                    document.getElementById("togglePlay").disabled = true;
                    document.getElementById("previousTrack").disabled = true;
                    document.getElementById("nextTrack").disabled = true;
                }
            });
            player.addListener('player_state_changed', ({
              position,
              duration,
              track_window: { current_track }
            }) => {
              var row = restaurantTracksTable.searchData("name", "=", current_track.name);
              if( row != null ) {
                  restaurantTracksTable.scrollToRow(row[0].id, "top", true);
              }
            });

            if( document.getElementById('togglePlay') != null ) {
                document.getElementById('togglePlay').onclick = function() {
                  player.togglePlay();
                };
            }

            if( document.getElementById('nextTrack') != null ) {
                document.getElementById('nextTrack').onclick = function() {
                  player.nextTrack();
                };
            }
            if( document.getElementById('previousTrack') != null ) {
                document.getElementById('previousTrack').onclick = function() {
                  player.previousTrack();
                };
            }
            player.connect();
        }

        restaurantTracksTable.on("rowMoved", function(row){
            const rows = restaurantTracksTable.getRows();
            for (let i = 0; i < rows.length; i++) {
                restaurantTracksTable.updateData([{id:rows[i].getData().id, sequence:rows[i].getPosition()}]);
                let mu = {
                  'track': {
                      'sequence': rows[i].getPosition()
                  }
                };
                fetch(rows[i].getData().url, {
                    method: 'PATCH',
                    headers:  {
                      "Content-Type": "application/json",
                      "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content
                    },
                    body: JSON.stringify(mu)
                });
            }
        });
        restaurantTracksTable.on("rowSelectionChanged", function(data, rows){
            if( data.length > 0 ) {
                document.getElementById("tracks-actions").disabled = false;
            } else {
                document.getElementById("tracks-actions").disabled = true;
            }
        });
        document.getElementById("activate-track").addEventListener("click", function(){
            const rows = restaurantTracksTable.getSelectedData();
            for (let i = 0; i < rows.length; i++) {
                restaurantTracksTable.updateData([{id:rows[i].id, status:'active'}]);
                let r = {
                  'track': {
                      'status': 'active'
                  }
                };
                patch( rows[i].url, r );
            }
        });
        document.getElementById("deactivate-track").addEventListener("click", function(){
            const rows = restaurantTracksTable.getSelectedData();
            for (let i = 0; i < rows.length; i++) {
                restaurantTracksTable.updateData([{id:rows[i].id, status:'inactive'}]);
                let r = {
                  'track': {
                      'status': 'inactive'
                  }
                };
                patch( rows[i].url, r );
            }
        });
        function patch( url, body ) {
                fetch(url, {
                    method: 'PATCH',
                    headers:  {
                      "Content-Type": "application/json",
                      "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content
                    },
                    body: JSON.stringify(body)
                });
        }
    }
}

