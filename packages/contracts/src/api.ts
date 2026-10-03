export interface ApiError { code:string; message:string; requestId?:string; }
export interface TranscriptionRequest { audio:Blob|ArrayBuffer; language?:string; mode:"offline"|"cloud"|"automatic"; context:{vocabulary:string[];replacements:Array<{trigger:string;replacement:string}>;snippets:Array<{trigger:string;expansion:string}>;styleId?:string;rules:string[]}; }
export interface TranscriptionResponse { rawText:string; text:string; provider:string; processing:{cleanupApplied:boolean;durationMs?:number}; }
export interface TransformRequest { text:string; operation:"polish"|"rewrite"|"shorten"|"expand"|"summarize"|"grammar"|"tone"|"custom"; instruction?:string; }
export interface TransformResponse { original:string; transformed:string; operation:TransformRequest["operation"]; }
