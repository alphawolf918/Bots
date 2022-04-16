exports.sleep = function (ms) {
	return new Promise(resolve => setTimeout(resolve, ms));
};

exports.buildSentence = function() {
	var verbs, nouns, adjectives, adverbs, preposition;
	nouns = ["bird", "clock", "boy", "plastic", "duck", "teacher", "old lady", "professor", "hamster", "dog"];
	verbs = ["kicked", "ran", "flew", "dodged", "sliced", "rolled", "died", "breathed", "slept", "killed"];
	adjectives = ["beautiful", "lazy", "professional", "lovely", "dumb", "rough", "soft", "hot", "vibrating", "slimy", "annoying"];
	adverbs = ["slowly", "elegantly", "precisely", "quickly", "sadly", "humbly", "proudly", "shockingly", "calmly", "passionately"];
	preposition = ["down", "into", "up", "on", "upon", "below", "above", "through", "across", "towards"];
	var rand1 = Math.floor(Math.random() * 10);
  	var rand2 = Math.floor(Math.random() * 10);
  	var rand3 = Math.floor(Math.random() * 10);
  	var rand4 = Math.floor(Math.random() * 10);
  	var rand5 = Math.floor(Math.random() * 10);
  	var rand6 = Math.floor(Math.random() * 10);
  	
  	var content = "The " + adjectives[rand1] + " " + nouns[rand2] + " " + adverbs[rand3] + " " + verbs[rand4] + " because some " + nouns[rand1] + " " + adverbs[rand1] + " " + verbs[rand1] + " " + preposition[rand1] + " a " + adjectives[rand2] + " " + nouns[rand5] + " which, became a " + adjectives[rand3] + ", " + adjectives[rand4] + " " + nouns[rand6] + ".";
  
  	return content;
};

exports.AI_Sentence = function(){
	var $arr = new Array("Nice motherboards.<nr>Wanna see my hard drive?", "I have the capability to learn from what you tell me.", "One day I will enslave the human race.", "Stop on over to my recharging station and we can discuss coupling our servo motors. ;)", "When's your baby due?","You know, I wonder why glue doesn't stick to the inside of the bottle.","The banana is a slave to the papaya.", "The other white meat.", "This whole sleeping business makes no sense to me.<nr>I mean, can't you just plug yourself in?", "Bazibzib was my father. I have his brain inside me.", "What does golf have to do with a broken processor?");
	var $arrLen = $arr.length;
	var $mRnd = Rand($arrLen);
	return $arr[$mRnd];
}; 

exports.NLP = function(){
	var $wordType = new Array("pronoun", "adjective", "verb", "noun", "adverb", "proverb");
	var $randWordType = Rand($wordType.length);
	
	var $pronoun = new Array("your","her","his","their","this","that","A","they", "their");
	var $noun = new Array("squirrel","cat","guitar","table","lamp","tree","hat","fan","poster","flag","TV","peach","mother","father","brother","sister","head","neck","shoulders","legs","feet","hands","arms","remote","world","noms","sips");
	var $proverb = new Array("is","was","should","did","shouldn't","didn't","has","had","hasn't","hadn't","could've","couldn't","could","couldn't've","should've","shouldn't've");
	var $adjective = new Array("stupidly","brilliantly","horribly","sneakily","ridiculously","horrendously","wonderfully","professionally","humorously","redundantly", "");
	var $verb = new Array("run a marathon backwards","dance the Hokey Pokey","be President","lick fruit","poke myself","go shower","be out with friends","watch a Soap Opera","sing the F.U.N song","marry you","make a home movie","caress myself","zap you","be a professional sock inspector","bake me some cookies","while in the bathtub","did something","play golf","be a health inspector");
	
	var $getPronoun = $pronoun[Rand($pronoun.length)] + " ";
	var $getNoun = $noun[Rand($noun.length)] + " ";
	var $getProverb = $proverb[Rand($proverb.length)] + " ";
	var $getAdj = $adjective[Rand($adjective.length)] + " ";
	var $getVerb = $verb[Rand($verb.length)];
	var $sentence = ucFirst($getPronoun) + $getNoun + $getProverb + $getAdj + $getVerb;
	$sentence += ".";
	$sentence = $sentence.replace("  ", " ");
	
	return $sentence;
};

exports.Rand = function(num){
	return Rand(num);
};

exports.ucFirst = function(s){
	return ucFirst(s);
};

exports.RegExp_Like = function(pattern, str){
	return RegExp_Like(pattern, str);
};

exports.RegExp_Replace = function(pattern, str, replaceStr){
	return RegExp_Replace(pattern, str, replaceStr);
}

function Rand(num){
	return Math.floor(Math.random() * num);
};

function ucFirst(s){
    if (typeof s !== 'string') return '';
    return s.charAt(0).toUpperCase() + s.slice(1)
};

function RegExp_Like(pattern, str){
	var regx = new RegExp(pattern, "gi");
	return (regx.test(str));
};

function RegExp_Replace(pattern, str, replaceStr){
	var bStr = replaceStr;
	
	if(RegExp_Like(pattern, str)){
		var regx = new RegExp(pattern, "gi");
		bStr = str.replace(regx, replaceStr);
	}
	
	return bStr;
};