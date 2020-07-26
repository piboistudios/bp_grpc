package bp.grpc;

import tink.chunk.ChunkCursor;
import tink.CoreApi;
import tink.io.StreamParser;
import tink.io.Source;
import tink.streams.Stream;
import tink.streams.RealStream;

@:forward
abstract GrpcReader<T>(GrpcStreamParserObject<T>) from GrpcStreamParserObject<T> to GrpcStreamParserObject<T> to tink.io.StreamParser<T> {
	

	@:to inline function get_stream():RealStream<T>
		return this.toStream();
	// @:
	// public function forEach<Safety>(handle:Handler<Item, Safety>):Future<Conclusion<Item, Safety, Quality>> {
	// 	return .forEach(handle);
}

interface GrpcStreamParserObject<T> extends tink.io.StreamParserObject<T> {
	public function toStream():RealStream<T>;
	public function prepare(source:RealSource):Void;
}

@:genericBuild(bp.grpc.Macros.GrpcStreamParserBuilder.buildParser())
class GrpcStreamParser<T> implements tink.io.StreamParserObject<T> {
	public function progress(cursor:ChunkCursor):ParseStep<T> {
		throw 'not implemented';
	}

	public function eof(rest:ChunkCursor):Outcome<T, Error> {
		throw 'not implemented';
	}
}

class GrpcStreamParserBase {
	var messageLength = -1;
	var buf:StringBuf;
	var text(get, never):String;
	var source:RealSource;

	public function new() {
		this.buf = new StringBuf();
	}
	public function prepare(source) {
		this.source = source;
	}

	function get_text()
		return buf.toString();

	inline function enqueue(cursor) {
		buf.addChar(cursor.currentByte);
	}
}
