package bp.grpc;

import tink.chunk.ChunkCursor;
import tink.CoreApi;
import tink.io.StreamParser;
import tink.io.Source;



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

	public function new() {
		this.buf = new StringBuf();
	}

	function get_text()
		return buf.toString();

	inline function enqueue(cursor) {
		buf.addChar(cursor.currentByte);
	}
}

