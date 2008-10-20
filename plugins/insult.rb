class Insult < PluginBase
  
  on_command 'insult', :insult
  
  def insult(msg)
    adj1 = adjective()
    adj2 = adjective()
    amount = amount()
    noun = noun()
    article = "a"
    article = "an" if (adj1[0] =~ /^[aeiou]/)
    out = "#{msg[:message]}, you are nothing but a #{adj1} #{amount} of #{adj2} #{noun}"
 
 
    speak(out)
  end
 
  
  private
  
  def adjective()
    adjectives = %w(acidic antique contemptible culturally-unsound despicable evil fermented
    festering foul fulminating humid impure inept inferior industrial
    left-over low-quality malodorous off-color penguin-molesting
    petrified pointy-nosed salty sausage-snorfling tastless tempestuous
    tepid tofu-nibbling unintelligent unoriginal uninspiring weasel-smelling
    wretched spam-sucking egg-sucking decayed halfbaked infected squishy
    porous pickled coughed-up thick vapid hacked-up
    unmuzzled bawdy vain lumpish churlish fobbing rank craven puking
    jarring fly-bitten pox-marked fen-sucked spongy droning gleeking warped
    currish milk-livered surly mammering ill-borne beef-witted tickle-brained
    half-faced headless wayward rump-fed onion-eyed beslubbering villainous
    lewd-minded cockered full-gorged rude-snouted crook-pated pribbling
    dread-bolted fool-born puny fawning sheep-biting dankish goatish
    weather-bitten knotty-pated malt-wormy saucyspleened motley-mind
    it-fowling vassal-willed loggerheaded clapper-clawed frothy ruttish
    clouted common-kissing pignutted folly-fallen plume-plucked flap-mouthed
    swag-bellied dizzy-eyed gorbellied weedy reeky measled spur-galled mangled
    impertinent bootless toad-spotted hasty-witted horn-beat yeasty
    imp-bladdereddle-headed boil-brained tottering hedge-born hugger-muggered 
    elf-skinned)
    
    adjectives[rand(adjectives.size)]
    
  end
  
  def amount()
    amounts = %w(accumulation bucket coagulation enema-bucketful gob half-mouthful
     heap mass mound petrification pile puddle stack thimbleful tongueful
     ooze quart bag plate ass-full assload)
     
     amounts[rand(amounts.size)]
    
  end

  def noun()
    nouns = %w(bat|toenails bug|spit cat|hair chicken|piss dog|vomit dung
    fat-woman's|stomach-bile fish|heads guano gunk pond|scum rat|retch
    red|dye|number-9 Sun|IPC|manuals waffle-house|grits yoo-hoo
    dog|balls seagull|puke cat|bladders pus urine|samples
    squirrel|guts snake|rectums snake|bait buzzard|gizzards
    cat-hair-balls rat-farts pods armadillo|snouts entrails
    snake|snot eel|ooze slurpee-backwash toxic|waste Stimpy-drool
    poopy poop craptacular|carpet|droppings cold|sores warts)
    
    nouns[rand(nouns.size)].sub("|", " ")
    
    
  end

end


