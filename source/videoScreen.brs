'
' Video playback screen
'

' Video screen constructor 
function VideoScreen()

    ' Member vars
    this = {}
    
    ' Member functions
    this.play = VideoScreen_play
    this.close = VideoScreen_close

    return this

end function

' Play a video and return if it was completely watched
function VideoScreen_play(contentItem) as Boolean

    this = m
    globals = getGlobalAA()
    
    this._port = CreateObject("roMessagePort")
    this._screen = CreateObject("roVideoScreen")
    this._screen.setMessagePort(this._port)

    watched = false
    position = loadPosition(contentItem)
    contentItem.playStart = position

    if position > 0 then
        globals.analytics.trackEvent("Tiny Desk", "Continue", contentItem.Title, "", [])
    else
        globals.analytics.trackEvent("Tiny Desk", "Start", contentItem.Title, "", [])
    end if

    print "Video playback will begin at: " position 

    this._screen.setPositionNotificationPeriod(1)
    this._screen.setContent(contentItem)
    this._screen.show()

    while true
        msg = wait(0, this._port)

        if msg.isScreenClosed()
            exit while
        else if msg.isRequestFailed()
            ' TODO
            print "Video request failure: "; msg.getIndex(); " " msg.getData()
        else if msg.isFullResult()
            position = 0
            savePosition(contentItem, position)

            watched = True
            playtime = position - contentItem.playStart

            globals.analytics.trackEvent("Tiny Desk", "Stop", contentItem.title, playtime.toStr(), [])
            globals.analytics.trackEvent("Tiny Desk", "Finish", contentItem.title, "", [])

            exit while
        else if msg.isPartialResult()
            playtime = position - contentItem.playStart
            globals.analytics.trackEvent("Tiny Desk", "Stop", contentItem.title, playtime.toStr(), [])

            ' If user watched more than 95% count video as watched
            if position >= int(contentItem.Length * 0.95) then
                position = 0
                savePosition(contentItem, position)

                watched = True
                globals.analytics.trackEvent("Tiny Desk", "Finish", contentItem.title, "", [])
            end if
        else if msg.isPlaybackPosition() then
            position = msg.getIndex()

            savePosition(contentItem, position)
        end if
    end while

    return watched

end function

function VideoScreen_close()

    this = m

    this._screen.close()

end function
