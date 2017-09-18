require 'faye/websocket'
require 'eventmachine'
require './wrappers'

game = start_game('chock_a_block')

@account = game['account']
@venue = game['venues'][0]
@symbol = game['tickers'][0]
@id = game['instanceId']

@quote_url = "#{WS_BASE_URL}/#{@account}/venues/#{@venue}/tickertape/stocks/#{@stock}"

EM.run {
  ws = Faye::WebSocket::Client.new(@quote_url)

  ws.on :open do |event|
    p [:open]
    #ws.send 'ok'
  end

  ws.on :message do |event|
    p [:message, event.data]
  end

  ws.on :close do |event|
    p [:close, event.code, event.reason]
    ws = nil
  end
}

@execution_url = "#{WS_BASE_URL}/#{@account}/venues/#{@venue}/executions/stocks/#{@stock}"
EM.run {
  ws = Faye::WebSocket::Client.new(@execution_url)

  ws.on :open do |event|
    p [:open]
  end

  ws.on :message do |event|
    p [:message, event.data]
  end

  ws.on :close do |event|
    p [:close, event.code, event.reason]
    ws = nil
  end
}
