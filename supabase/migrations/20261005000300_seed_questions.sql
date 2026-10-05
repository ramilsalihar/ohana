-- Starter question bank for the daily question (PRD F2).
--
-- Each question has a category (fun, deep, future, memories, intimacy-light)
-- and a relationship stage (dating, long-term, any) so the same bank serves
-- both personas. Tone: warm, calm, grown-up. Questions are answerable in a
-- sentence or two and never ask one partner to judge the other.

alter table public.questions
  add constraint questions_text_key unique (text);

insert into public.questions (category, stage, text) values
  -- fun
  ('fun', 'any', 'What small thing made you smile today?'),
  ('fun', 'any', 'If we had a free Saturday with no plans, how would you spend it with me?'),
  ('fun', 'any', 'Which meal could you happily eat every week for the rest of your life?'),
  ('fun', 'any', 'What song would be on the soundtrack of us?'),
  ('fun', 'any', 'What is something you are oddly good at that I might not know about?'),
  ('fun', 'any', 'If we could wake up anywhere tomorrow, where would you pick?'),
  ('fun', 'any', 'What show or film do you wish you could watch again for the first time?'),
  ('fun', 'dating', 'What is something you would love to try together for the first time?'),
  ('fun', 'long-term', 'Which of our everyday routines do you secretly enjoy the most?'),
  ('fun', 'long-term', 'What is an inside joke of ours that still makes you laugh?'),

  -- deep
  ('deep', 'any', 'What has been on your mind lately that you have not said out loud?'),
  ('deep', 'any', 'When do you feel most like yourself?'),
  ('deep', 'any', 'What is something you are proud of that rarely gets noticed?'),
  ('deep', 'any', 'What helps you most when you have had a hard day?'),
  ('deep', 'any', 'What is a belief you have changed your mind about over the years?'),
  ('deep', 'any', 'What does feeling supported look like for you right now?'),
  ('deep', 'any', 'Who has shaped you the most, and how?'),
  ('deep', 'dating', 'What is something about you that takes people a while to understand?'),
  ('deep', 'long-term', 'How have you changed since we first got together?'),
  ('deep', 'long-term', 'What is something you would like more room for in your life at the moment?'),

  -- future
  ('future', 'any', 'What are you looking forward to in the next month?'),
  ('future', 'any', 'What is one place you would love us to visit someday?'),
  ('future', 'any', 'What skill would you like to learn in the next few years?'),
  ('future', 'any', 'What does a really good ordinary day look like for you five years from now?'),
  ('future', 'any', 'What is a tradition you would like us to start?'),
  ('future', 'any', 'What is one thing you would like us to do more of this year?'),
  ('future', 'dating', 'What does home mean to you, and what would you want yours to feel like?'),
  ('future', 'dating', 'What are you hoping the next year holds for you?'),
  ('future', 'long-term', 'What is a dream of yours we have not talked about in a while?'),
  ('future', 'long-term', 'What would you like our weekends to look like a few years from now?'),

  -- memories
  ('memories', 'any', 'What is a favourite memory of us from the past year?'),
  ('memories', 'any', 'What is a moment with me that you wish you could relive?'),
  ('memories', 'any', 'What is your happiest childhood memory?'),
  ('memories', 'any', 'When did you last laugh so hard it hurt?'),
  ('memories', 'any', 'What is the best trip or outing we have had together?'),
  ('memories', 'any', 'What is a small moment between us that stayed with you?'),
  ('memories', 'dating', 'What do you remember about the first time we met?'),
  ('memories', 'dating', 'When did you first realise you wanted to keep seeing me?'),
  ('memories', 'long-term', 'What is a hard time we got through that you are glad we faced together?'),
  ('memories', 'long-term', 'What do you remember about the early days of us that still makes you smile?'),

  -- intimacy-light
  ('intimacy-light', 'any', 'What is something I do that makes you feel cared for?'),
  ('intimacy-light', 'any', 'When do you feel closest to me?'),
  ('intimacy-light', 'any', 'What is a small gesture that means a lot to you?'),
  ('intimacy-light', 'any', 'What is your favourite way for us to spend a quiet evening?'),
  ('intimacy-light', 'any', 'What is something you appreciate about how we talk to each other?'),
  ('intimacy-light', 'any', 'How do you most like to be comforted?'),
  ('intimacy-light', 'any', 'What is a compliment you have received that you still think about?'),
  ('intimacy-light', 'dating', 'What made you feel at ease with me early on?'),
  ('intimacy-light', 'long-term', 'What is something about me you have come to love more over time?'),
  ('intimacy-light', 'long-term', 'What is one small thing we could do this week to feel a little closer?')
on conflict (text) do nothing;
