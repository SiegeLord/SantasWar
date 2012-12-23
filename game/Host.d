module game.Host;

import game.Disposable;
import game.IMessage;
import game.Channel;
import game.UnorderedEvent;

import game.messages.TestMessage;
import game.messages.StateMessage;
import game.messages.InputMessage;
import game.messages.NameMessage;
import game.messages.MapInitMessage;
import game.messages.UIMessage;

import enet.enet;

import core.memory;

import tango.core.Array;
import tango.io.device.Array;
import tango.io.stream.Data;
import tango.io.Stdout;

class CHost : CDisposable
{	
	this(ushort port)
	{
		IsServer = true;
		
		ENetAddress address;
		address.host = ENET_HOST_ANY;
		address.port = port;
		Port = port;
				
		Host = enet_host_create(&address, 32, 1, 0, 0);
		
		CreateEvents();
	}
	
	this()
	{
		Host = enet_host_create(null, 1, 1, 0, 0);
		
		CreateEvents();
	}
	
	@property
	bool Valid()
	{
		return Host !is null;
	}
	
	override
	void Dispose()
	{
		super.Dispose();
		if(Host !is null)
			enet_host_destroy(Host);
	}

	class CNetChannel : CChannel
	{
		this(ENetPeer* peer)
		{
			Peer = peer;
		}
		
		override
		void Send(IMessage message)
		{
			if(DisconnectAll)
				return;
			auto array = new Array(128, 1024);
			auto data = new DataOutput(array);
			
			data.int32(cast(int)message.Type);
			message.Write(data);
			data.flush();
			
			auto packet = enet_packet_create(array.slice().ptr, array.slice().length, ENetPacketFlag.ENET_PACKET_FLAG_RELIABLE);
			assert(packet);
			auto ret = enet_peer_send(Peer, 0, packet);
			assert(ret == 0);
		}
	protected:
		ENetPeer* Peer;
	}
	
	void Connect(const(char)[] hostname, ushort port)
	{		
		ENetAddress address;
		address.port = port;
		
		Stdout("Connecting to", hostname).nl;
		auto ret = enet_address_set_host(&address, (hostname ~ "\0").ptr);
		assert(ret == 0);
		
		auto peer = enet_host_connect(Host, &address, 1, 0);
		assert(peer);
	}
	
	void Disconnect()
	{
		DisconnectAll = true;
		foreach(peer; Peers)
		{
			enet_peer_disconnect(peer, 0);
		}
	}
		
	void Logic(float dt)
	{
		ENetEvent event;
		while(enet_host_service(Host, &event, 0) > 0)
		{
			switch(event.type)
			{
				case ENetEventType.ENET_EVENT_TYPE_CONNECT:
					if(DisconnectAll)
					{
						enet_peer_disconnect(event.peer, 0);
					}
					else
					{
						Stdout("Somebody connected").nl;
						auto channel = new CNetChannel(event.peer);
						event.peer.data = cast(void*)(channel);
						Peers ~= event.peer;
						
						GC.addRoot(event.peer.data);
						
						ConnectionEvent.Trigger(channel);
					}
					break;
				case ENetEventType.ENET_EVENT_TYPE_RECEIVE:
					auto array = new Array(event.packet.data[0..event.packet.dataLength]);
					auto data = new DataInput(array);
					
					//Stdout("Got packet of size:", event.packet.dataLength).nl;
					
					auto type = cast(EMessageType)data.int32();
					
					IMessage mess;
					final switch(type)
					{
						case EMessageType.State:
							mess = new CStateMessage();
							break;
						case EMessageType.Input:
							mess = new CInputMessage();
							break;
						case EMessageType.Test:
							mess = new CTestMessage();
							break;
						case EMessageType.Name:
							mess = new CNameMessage();
							break;
						case EMessageType.MapInit:
							mess = new CMapInitMessage();
							break;
						case EMessageType.UI:
							mess = new CUIMessage();
							break;
					}
					mess.Read(data);
					
					(cast(CNetChannel)event.peer.data).ReceiveEvent.Trigger(mess);
					
					enet_packet_destroy(event.packet);
					
					break;
				case ENetEventType.ENET_EVENT_TYPE_DISCONNECT:
					Stdout("Somebody disconnected...").nl;
					if(event.peer.data !is null)
					{
						DisconnectionEvent.Trigger(cast(CNetChannel)event.peer.data);
					}
					
					GC.removeRoot(event.peer.data);
				
					auto new_length = Peers.partition((ENetPeer* p) => p != event.peer);
					Peers.length = new_length;
					if(Peers.length == 0)
					{
						AllDisconnectedEvent.Trigger();
					}
					break;
				default: {}
			}
		}
	}
	
	@property
	size_t NumPeers()
	{
		return Peers.length;
	}
	
	CUnorderedEvent!(CChannel) ConnectionEvent;
	CUnorderedEvent!(CChannel) DisconnectionEvent;
	CUnorderedEvent!() AllDisconnectedEvent;
protected:
	void CreateEvents()
	{
		ConnectionEvent = new typeof(ConnectionEvent);
		DisconnectionEvent = new typeof(DisconnectionEvent);
		AllDisconnectedEvent = new typeof(AllDisconnectedEvent);
	}

	bool DisconnectAll = false;
	bool IsServer = false;
	ENetHost* Host;
	ENetPeer*[] Peers;
	ushort Port;
}
