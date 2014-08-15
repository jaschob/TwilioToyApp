# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/


REGEX_COIN_AMOUNT = ///
    ^ \d+ (?:
        [.] \d{0,8}
    )? $
///

# Page setup (called when the document is fully loaded)
on_dashboard_load = () ->

    ###
    # Define global helpers and classes
    ###

    # generates a new table row with the specified number of columns
    new_hidden_row = (num_columns = 0) ->
        tr = $( "<tr/>", {
            class: "hidden"
        })
        for i in [1..num_columns]
            tr.append( $( "<td/>" ) )

        tr
        
    # Superclass for all calls to the transactions_controller. Handles things
    # like providing information in the title bar etc.
    class AjaxCall
        constructor: (@url, @method = "get", @show_overall_status = true) ->
            @callbacks = {
                success: []
                error: []
                complete: []
            }
                
        make_call: (method_args) =>
            @on_begin()
            @jqXHR = $.ajax(
                url: @url
                data: method_args
                type: @method
                dataType: 'json'
                success: (a...)  => @on_success(a...)
                error: (a...)    => @on_error(a...)
                complete: (a...) => @on_complete(a...)
            )

            @jqXHR.done(cb) for cb in @callbacks['success']
            @jqXHR.fail(cb) for cb in @callbacks['error']
            @jqXHR.always(cb) for cb in @callbacks['complete']

        on_begin: =>
            @update_status('ajax-bar', 'inprogress') if @show_overall_status

        on_success: (data, textStatus, jqXHR) =>
            @update_status('ajax-bar', "null") if @show_overall_status

        on_error: (jqXHR, textStatus, errorThrown) =>
            @update_status('ajax-bar', 'error',
            if @show_overall_status
                "Error: #{jqXHR.responseText.substring(0, 100)}")

        on_complete: =>
            # nothing as of yet

        add_callback: (state, cb) ->
            # if @jqXHR is set, the AJAX call has already been initiated
            if @jqXHR
                switch state
                    when 'success' then @jqXHR.done(cb)
                    when 'error' then @jqXHR.fail(cb)
                    when 'complete' then @jqXHR.always(cb)
                    
            # otherwise, we save the callback and add it later in make_call
            else
                @callbacks[state].push cb

        update_status: (area, state, message = null) ->
            ajax_node = $( "##{area}" )
            status_nodes = $( ".ajax", ajax_node )
            target_node = $( ".ajax.#{state}", ajax_node )
            target_msg_node = $( "span", target_node )
            if target_msg_node.size() < 1 and target_node.size() > 0
                target_msg_node = target_node

            status_nodes.each(->
                $( this ).hide() unless state and $( this ).hasClass(state))

            return unless target_node.size()

            # track the original (default) message in the span
            if not target_msg_node.data("default_message")
                target_msg_node.data("default_message", target_msg_node.html())

            if message
                target_msg_node.html(message)
            else
                target_msg_node.html(target_msg_node.data("default_message"))

            target_node.show()

    # Helper that can group multiple calls (executing them in order)
    class MultiLoadCall extends AjaxCall
        constructor: (@work = []) ->
            # turn off overall status for workers since we'll handle it
            w.show_overall_status = false for w in @work
                
        # assumption is, each call won't have arguments
        make_call: () =>
            @errors = []
            @completed = 0
            @update_status('ajax-bar', 'inprogress',
            "Refreshing information...")
            
            for w in @work
                w.make_call()
                w.add_callback('error', => @track_error())
                w.add_callback('complete', => @track_complete())

        track_error: (jqXHR, textStatus, errorThrown) =>
            push @errors, jqXHR.responseText

        track_complete: () =>
            @completed++
            if @completed >= @work.length and @errors.length > 0
                @update_status "ajax-bar", "error",
                @errors[0]
                # just showing the first error
                
            else if @completed >= @work.length
                @update_status "ajax-bar", "done",
                "Information refreshed from bitcoin network."

                bar = $( "#ajax-bar" )
                $( ".ajax.done", bar ).delay(6000).fadeOut()
                
                

    # Checks if there were any recent changes
    class Poller extends AjaxCall
        constructor: () -> super AJAX_POLL.data("path"), "get", false

        start: (interval = 5000) ->
            setInterval (do => @make_call), interval

        on_success: (data, other...) ->
            super data, other...
            
            best_block = data['best_block']
            activity = new Date(data['activity'])
            last_best_block = AJAX_POLL.data("best_block")
            last_activity = AJAX_POLL.data("activity")

            # something has happened!
            if best_block isnt last_best_block or
            activity.getTime() > last_activity.getTime()
                $( "#refresh" ).click()

            # save the new best block and activity time
            AJAX_POLL.data("best_block", best_block)
            AJAX_POLL.data("activity", activity)

    # Refresh the information about other users (primarily balances!)
    class LoadUserInfo extends AjaxCall
        FIND_ROW: (table, username) ->
            found = null
            $( "tr", table ).each ->
                td = $( this )
                td_user = td.attr("id").substr("userinfo-".length)
                if td_user is username
                    found = td

            return found

        constructor: -> super AJAX_USERINFO.data("path")

        on_success: (data, other...) =>
            super data, other...

            tbl = $( "#userinfo-table" )
            tbl_rows = $( "tr", tbl )
            tbl_size = tbl_rows.size()

            for json in data
                json_user = json['username']
                json_balance = json['balance']['html']
                row = @FIND_ROW(tbl, json_user)

                # add a row to the end of the table
                if not row
                    row = new_hidden_row(2)
                    row.attr("id", "userinfo-#{json_user}")
                    row.addClass("side-bar-usr-row")
                    switch ++tbl_size % 2
                        when 0 then row.addClass("row-even")
                        when 1 then row.addClass("row-odd")

                    col_user = $( $( "td", row )[0] )
                    col_user.html(json_user)

                    tbl.append(row)

                row_balance = $( $( "td", row )[1] ).html().trim()

                if json_balance isnt row_balance
                    $( $( "td", row )[1] ).text(json_balance)
                    row.fadeIn(1200)

    # Refreshes the current user's balance
    class LoadBalance extends AjaxCall
        constructor: -> super AJAX_BALANCE.data("path")

        on_begin: (other...) =>
            super other
            @update_status("side-bar-balance", "inprogress")

        on_success: (data, other...) =>
            super data, other...
            @update_status("side-bar-balance", "done",
            data['balance']['html'])

    # Refreshes the recent transaction list
    class LoadRecentTx extends AjaxCall
        constructor: -> super AJAX_RECENTTX.data("path")

        on_success: (data, other...) =>
            super data, other...

            empty_msg = $( "#recent-tx-none" )
            tbl = $( "#recent-tx-table" )
            tbl_header = $( "#recent-tx-table tr:first-child" )
            tbl_rows = $( "tr", tbl ).not(":first")
            tbl_size = tbl_rows.size()
            fadeInElements = []

            for json in data
                json_txid = json['id']['raw']
                row = $( "#tx-#{json_txid}", tbl )
                row_existed = row.size() > 0

                # add row if necessary
                unless row_existed
                    row = new_hidden_row(6)
                    row.attr("id", "tx-#{json_txid}")
                    fadeInElements.push(row)
                    
                    tbl_header.after(row)
                    tbl_size++
                    
                # check for column changes
                changed = false
                for key, i in ["date", "category", "amount", "id",
                               "confirmations", "blockhash"]
                    col = $( $( "td", row )[i] )
                    row_val = col.html().trim()
                    json_val = json[key]['html']
                    if json_val isnt row_val
                        col.html(json_val)
                        changed = true
                        
                fadeInElements.push(row) if changed

            # remove older rows now
            tbl_rows = $( "tr", tbl ).not(":first")
            while tbl_size > 7  # ugh, should be dynamic!!
                $( "tr:last", tbl ).remove()
                tbl_size--

            # re-colorize the rows, since it may be all messed up
            $( "tr:even", tbl ).not(":first").removeClass("row-odd")
            $( "tr:even", tbl ).not(":first").addClass("row-even")
            $( "tr:odd", tbl ).removeClass("row-even")
            $( "tr:odd", tbl ).addClass("row-odd")

            # if we have table content, make sure we show it
            if tbl_size < 1
                empty_msg.show()
                tbl.hide()
            else
                empty_msg.hide()
                tbl.show()

            # fade in all the elements that are new or changed
            element.fadeIn(1200) for element in fadeInElements

    # Issues a txsend via the bitcoin client!
    class TxSend extends AjaxCall
        constructor: (@balance_txt, @amount_txt, @recipient) ->
            super AJAX_SEND.data("path"), "post", false

        validate_coin_amount: =>
            @amount_txt = @amount_txt.trim()
            if not @amount_txt
                alert "No amount entered!"
            else if not REGEX_COIN_AMOUNT.exec(@amount_txt)
                alert "#{@amount_txt} is not a valid amount!"
                false
            else
                @amount = parseFloat(@amount_txt)
                true

        validate_transaction: =>
            @balance = parseFloat(@balance_txt)
            if @amount <= 0
                alert "Please enter a positive amount!"
                false

            else if @balance - @amount < 0
                alert "Your current balance can't cover the transaction amount!"
                false
            else
                true

        make_call: ->
            if @validate_coin_amount() and @validate_transaction()
                super { recipient: @recipient, amount: @amount }

        on_begin: =>
            super
            @update_status('tx-send-status', 'inprogress',
            "Sending #{@amount} BTC...")

        on_success: (data, textStatus, jqXHR) =>
            super data, textStatus, jqXHR
            @update_status("tx-send-status", "success", data["message"])

        on_error: (jqXHR, textStatus, errorThrown) =>
            super jqXHR, textStatus, errorThrown
            @update_status("tx-send-status", "error", jqXHR.responseText)

        on_complete: =>
            super
            new LoadBalance().make_call()

    ###
    # Page setup
    ###
    
    # use hidden inputs to stash data
    AJAX_POLL = $( "#ajax_poll_path" )
    AJAX_BALANCE = $( "#ajax_balance_path" )
    AJAX_USERINFO = $( "#ajax_userinfo_path" )
    AJAX_RECENTTX = $( "#ajax_recenttx_path" )
    AJAX_SEND = $( "#ajax_send_path" )

    AJAX_POLL.data("path", AJAX_POLL.val())
    AJAX_POLL.data("best_block", $( "#best_block" ).val())
    AJAX_POLL.data("activity", new Date( $("#load_time").val() ))
    AJAX_BALANCE.data("path", AJAX_BALANCE.val())
    AJAX_SEND.data("path", AJAX_SEND.val())
    AJAX_USERINFO.data("path", AJAX_USERINFO.val())
    AJAX_RECENTTX.data("path", AJAX_RECENTTX.val())

    # hook up event handlers

    # close button in status div and paragraphs
    $( ".ajax.success img, .ajax.error img" ).click(->
        $( this ).parent("div, p").fadeOut())

    # refresh button for a full refresh
    $( "#refresh" ).click(->
        new MultiLoadCall([
            new LoadBalance(),
            new LoadUserInfo(),
            new LoadRecentTx()]).make_call())
    
    # send bitcoin button
    $( "#send_tx_btn" ).click ->
        balance = $( "#send_tx_current_balance" ).val()
        tx_amount = $( "#send_tx_amount" ).val()
        recipient = $( "#send_tx_recipient" ).val()

        new TxSend(balance, tx_amount, recipient).make_call()
        
    # set up a poller that checks the system every so often. if activity is
    # detected, it'll fire a full refresh, via the #send_tx_btn link
    new Poller().start(20000)   # check every 20 seconds

#####
# Calls on_dashboard_load for only the dashboard page
#####
$( "document" ).ready ->
    controller = $( "body" ).attr("data-controller")
    action = $( "body" ).attr("data-action")
    
    if controller is "dashboard"
        on_dashboard_load()
