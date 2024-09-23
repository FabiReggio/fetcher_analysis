SELECT 
ce.email_sender AS "Email Sender", 
case 
    when ce.email_sender=0 then 'Sendgrid' 
    when ce.email_sender=1 then 'Gmail' 
    when ce.email_sender=2 then 'Outlook' 
end as "Email Sender",
str_to_date(concat(date_format(ce.created, '%Y-%m'), '-01'), '%Y-%m-%d') AS "created", 
count(*) AS "count"
FROM candidate_message ce
GROUP BY ce.email_sender, str_to_date(concat(date_format(ce.created, '%Y-%m'), '-01'), '%Y-%m-%d')
ORDER BY ce.email_sender ASC, str_to_date(concat(date_format(ce.created, '%Y-%m'), '-01'), '%Y-%m-%d') ASC;