package bp.grpc;

import tink.macro.BuildCache;

using tink.MacroApi;

class GrpcStreamParserBuilder {
	public static function buildWriter()
		return tink.macro.BuildCache.getType('bp.grpc.GrpcStreamWriter', doBuildWriter);

	public static function buildParser()
		return tink.macro.BuildCache.getType('bp.grpc.GrpcStreamParser', doBuildParser);

	

	static function doBuildWriter(ctx:BuildContext) {
		
		var name = ctx.name;
		var ct = ctx.type.toComplex();
		
		var cl = macro class $name extends bp.grpc.GrpcStreamWriter.GrpcStreamWriterBase<$ct> {
			var writer:tink.json.Writer<$ct>;

			public function new() {
				this.writer = new tink.json.Writer<$ct>();
				this.signal = tink.core.Signal.trigger();
			}

			override public function write(object:$ct) {
				var output:String = writer.write(object);
				var data = Std.string(output.length) + '\r\n' + output;
				signal.trigger(Data(data));
			}
		}
		
		return cl;
	}

	static function doBuildParser(ctx:BuildContext) {
		var name = ctx.name;
		var ct = ctx.type.toComplex();
		var cl = macro class $name extends bp.grpc.GrpcStreamParser.GrpcStreamParserBase implements bp.grpc.GrpcStreamParser.GrpcStreamParserObject<$ct> implements tink.io.StreamParser.StreamParserObject<$ct> {
			var parser:tink.json.Parser<$ct>;

			public function new() {
				super();
				this.parser = new tink.json.Parser<$ct>();
			}
			public function toStream() {
				var message = tink.core.Signal.trigger();
				var stream = new tink.streams.Stream.SignalStream(message);
				function parse()
					return tink.io.Source.RealSourceTools.parse(this.source,this).next(result -> {
						message.trigger(Data(result.a));
						if(result.b.depleted) message.trigger(End);
						else {
							this.source = result.b;
							parse();
						}
						tink.core.Noise;
					}).eager();
				parse();
				return stream;
			}
			public function progress(cursor:tink.chunk.ChunkCursor) {
				if (messageLength == -1) {
					return readLength(cursor);
				} else {
					return readMessage(cursor);
				}
			}

			public function eof(rest:tink.chunk.ChunkCursor) {
				return tink.core.Outcome.Success(null);
			}

			function readLength(cursor:tink.chunk.ChunkCursor):tink.io.StreamParser.ParseStep<$ct> {
				do {
					enqueue(cursor);
				} while (text.indexOf('\r\n') == -1 && cursor.next());
				if (text.indexOf('\r\n') == -1)
					return Progressed;

				var len = Std.parseInt(text);
				if (len == null) {
					return Failed(new tink.core.Error('Expected int, got: ' + text));
				} else {
					this.messageLength = len;
					this.buf = new StringBuf();
					return Progressed;
				}
			}

			function readMessage(cursor:tink.chunk.ChunkCursor):tink.io.StreamParser.ParseStep<$ct> {
				var len = this.messageLength;
				if (len == 0) {
					this.messageLength = -1;
					return Done(null);
				}
				do {
					enqueue(cursor);
				} while (len-- >= 0 && cursor.next());
				if (len > 0)
					return Progressed;
				else {
					this.messageLength = -1;
					var v:$ct = parser.parse(text);
					this.buf = new StringBuf();
					return Done(v);
				}
			}
		}
		return cl;
	}
}
