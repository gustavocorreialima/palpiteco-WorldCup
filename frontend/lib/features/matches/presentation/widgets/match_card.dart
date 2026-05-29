import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../domain/entities/match.dart';

// ===========================================================================
// PREMIUM MATCH CARD
// ===========================================================================
class MatchCard extends StatefulWidget {
  final Match match;
  final Bet? userBet;
  final void Function(int home, int away)? onBetSubmit;
  final bool isExpanded;

  const MatchCard({
    super.key,
    required this.match,
    this.userBet,
    this.onBetSubmit,
    this.isExpanded = false,
  });

  @override
  State<MatchCard> createState() => _MatchCardState();
}

class _MatchCardState extends State<MatchCard> with SingleTickerProviderStateMixin {
  late AnimationController _expandCtrl;
  late Animation<double> _expandAnim;
  late Animation<double> _arrowAnim;

  int _homeScore = 0;
  int _awayScore = 0;
  bool _betSubmitted = false;

  @override
  void initState() {
    super.initState();
    _expandCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _expandAnim = CurvedAnimation(parent: _expandCtrl, curve: Curves.easeInOutCubic);
    _arrowAnim  = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _expandCtrl, curve: Curves.easeInOut),
    );
    if (widget.isExpanded) _expandCtrl.value = 1.0;
  }

  @override
  void dispose() {
    _expandCtrl.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    HapticFeedback.selectionClick();
    _expandCtrl.isCompleted ? _expandCtrl.reverse() : _expandCtrl.forward();
  }

  void _submitBet() {
    HapticFeedback.mediumImpact();
    widget.onBetSubmit?.call(_homeScore, _awayScore);
    setState(() => _betSubmitted = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _betSubmitted = false);
    });
  }

  Color get _cardBorderColor {
    if (widget.match.isLive) return AppColors.liveRed.withOpacity(0.4);
    if (widget.match.isFinished) return AppColors.cardBorder;
    return AppColors.neonBlue.withOpacity(0.2);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: _cardBorderColor, width: 1),
        boxShadow: AppColors.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top accent line for live
            if (widget.match.isLive)
              Container(
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, AppColors.liveRed, Colors.transparent],
                  ),
                ),
              ),

            _CardHeader(match: widget.match),
            _TeamsRow(match: widget.match, userBet: widget.userBet),

            SizeTransition(
              sizeFactor: _expandAnim,
              child: Column(
                children: [
                  const Divider(height: 1, color: AppColors.cardBorder, indent: 16, endIndent: 16),
                  if (widget.match.h2hStats != null)
                    _H2HPanel(match: widget.match),
                  if (widget.match.isScheduled && widget.onBetSubmit != null) ...[
                    const Divider(height: 1, color: AppColors.cardBorder, indent: 16, endIndent: 16),
                    _BetInputPanel(
                      homeScore: _homeScore,
                      awayScore: _awayScore,
                      homeLabel: widget.match.homeTeam.shortName ?? widget.match.homeTeam.name,
                      awayLabel: widget.match.awayTeam.shortName ?? widget.match.awayTeam.name,
                      submitted: _betSubmitted,
                      onHomeChange: (v) => setState(() => _homeScore = v),
                      onAwayChange: (v) => setState(() => _awayScore = v),
                      onSubmit: _submitBet,
                    ),
                  ],
                  if (widget.match.isLive && widget.match.liveEvents.isNotEmpty) ...[
                    const Divider(height: 1, color: AppColors.cardBorder, indent: 16, endIndent: 16),
                    _LiveEventsPanel(events: widget.match.liveEvents),
                  ],
                ],
              ),
            ),

            _ExpandButton(arrowAnim: _arrowAnim, onTap: _toggleExpand),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// CARD HEADER
// ===========================================================================
class _CardHeader extends StatelessWidget {
  final Match match;
  const _CardHeader({required this.match});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          CircleAvatar(
            radius: 10,
            backgroundColor: AppColors.cardBorder,
            backgroundImage: match.competition.logoUrl != null
                ? NetworkImage(match.competition.logoUrl!)
                : null,
            child: match.competition.logoUrl == null
                ? const Icon(Icons.emoji_events_rounded, size: 10, color: AppColors.textMuted)
                : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${match.group ?? match.competition.name}  ·  ${match.round ?? match.competition.round ?? ""}',
              style: AppTextStyles.caption,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _StatusChip(match: match),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final Match match;
  const _StatusChip({required this.match});

  @override
  Widget build(BuildContext context) {
    if (match.isLive) return const LiveBadge(label: 'AO VIVO', color: AppColors.liveRed, fontSize: 9);

    final label = match.isFinished ? 'FIM' : _formatTime(match.kickoffAt);
    final color = match.isFinished ? AppColors.textMuted : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Text(label, style: AppTextStyles.caption.copyWith(color: color, fontSize: 10)),
    );
  }

  static String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

// ===========================================================================
// TEAMS ROW
// ===========================================================================
class _TeamsRow extends StatelessWidget {
  final Match match;
  final Bet? userBet;
  const _TeamsRow({required this.match, this.userBet});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: _TeamInfo(team: match.homeTeam, align: CrossAxisAlignment.start),
          ),
          _ScoreCenter(match: match, userBet: userBet),
          Expanded(
            child: _TeamInfo(team: match.awayTeam, align: CrossAxisAlignment.end),
          ),
        ],
      ),
    );
  }
}

class _TeamInfo extends StatelessWidget {
  final Team team;
  final CrossAxisAlignment align;
  const _TeamInfo({required this.team, required this.align});

  @override
  Widget build(BuildContext context) {
    final isStart = align == CrossAxisAlignment.start;
    return Column(
      crossAxisAlignment: align,
      children: [
        TeamFlag(url: team.flagUrl ?? team.logoUrl, size: 52, withGlow: false),
        const SizedBox(height: 8),
        Text(
          team.shortName ?? team.name,
          style: AppTextStyles.teamName,
          textAlign: isStart ? TextAlign.left : TextAlign.right,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _ScoreCenter extends StatelessWidget {
  final Match match;
  final Bet? userBet;
  const _ScoreCenter({required this.match, this.userBet});

  @override
  Widget build(BuildContext context) {
    if (match.isLive || match.isFinished) {
      return Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ScoreDigit(value: match.homeScoreFt ?? 0, isLive: match.isLive),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text('–', style: AppTextStyles.scoreVs),
              ),
              _ScoreDigit(value: match.awayScoreFt ?? 0, isLive: match.isLive),
            ],
          ),
          const SizedBox(height: 4),
          if (match.isLive)
            Text("${match.liveMinute ?? 0}'", style: AppTextStyles.caption.copyWith(color: AppColors.neonGreen, fontWeight: FontWeight.w700))
          else
            Text('Final', style: AppTextStyles.caption),
          if (userBet != null) _BetResultBadge(bet: userBet!),
        ],
      );
    }

    return Column(
      children: [
        Text('VS', style: AppTextStyles.scoreVs.copyWith(fontSize: 20)),
        const SizedBox(height: 6),
        if (userBet != null)
          _UserBetPreview(bet: userBet!)
        else
          _KickoffCountdown(kickoffAt: match.kickoffAt),
      ],
    );
  }
}

class _ScoreDigit extends StatelessWidget {
  final int value;
  final bool isLive;
  const _ScoreDigit({required this.value, this.isLive = false});

  @override
  Widget build(BuildContext context) {
    return Text(
      '$value',
      style: AppTextStyles.scoreDigit.copyWith(
        color: isLive ? AppColors.neonGreen : AppColors.textPrimary,
        shadows: isLive
            ? [Shadow(color: AppColors.neonGreen.withOpacity(0.5), blurRadius: 12)]
            : null,
      ),
    );
  }
}

class _BetResultBadge extends StatelessWidget {
  final Bet bet;
  const _BetResultBadge({required this.bet});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (bet.result) {
      case BetResult.exact:
        color = AppColors.neonGreen; label = '+${bet.pointsEarned ?? 10} pts ⚡'; break;
      case BetResult.correct:
        color = AppColors.neonBlue; label = '+${bet.pointsEarned ?? 5} pts ✓'; break;
      case BetResult.wrong:
        color = AppColors.liveRed; label = '0 pts ✗'; break;
      default:
        color = AppColors.textMuted; label = '${bet.homeScore}–${bet.awayScore}';
    }
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label, style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.w700, fontSize: 10)),
    );
  }
}

class _UserBetPreview extends StatelessWidget {
  final Bet bet;
  const _UserBetPreview({required this.bet});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.neonBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: AppColors.neonBlue.withOpacity(0.3)),
      ),
      child: Text(
        'Palpite: ${bet.homeScore}–${bet.awayScore}',
        style: AppTextStyles.caption.copyWith(color: AppColors.neonBlue, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _KickoffCountdown extends StatelessWidget {
  final DateTime kickoffAt;
  const _KickoffCountdown({required this.kickoffAt});

  @override
  Widget build(BuildContext context) {
    final diff = kickoffAt.difference(DateTime.now());
    if (diff.inHours < 24) {
      return CountdownTimer(target: kickoffAt);
    }
    final days = diff.inDays;
    return Text('em $days dias', style: AppTextStyles.caption);
  }
}

// ===========================================================================
// H2H PANEL
// ===========================================================================
class _H2HPanel extends StatelessWidget {
  final Match match;
  const _H2HPanel({required this.match});

  @override
  Widget build(BuildContext context) {
    final h2h = match.h2hStats!;
    final total = (h2h.teamAWins + h2h.draws + h2h.teamBWins).toDouble();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Confronto Direto (últimos ${h2h.lastNMatches})', style: AppTextStyles.label),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _H2HBar(
                  label: '${match.homeTeam.shortName ?? match.homeTeam.name} ${h2h.teamAWins}',
                  flex: total > 0 ? h2h.teamAWins / total : 0,
                  color: AppColors.neonBlue,
                  alignLeft: true,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    Text('${h2h.draws}', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
                    Text('E', style: AppTextStyles.caption.copyWith(fontSize: 9)),
                  ],
                ),
              ),
              Expanded(
                child: _H2HBar(
                  label: '${h2h.teamBWins} ${match.awayTeam.shortName ?? match.awayTeam.name}',
                  flex: total > 0 ? h2h.teamBWins / total : 0,
                  color: AppColors.liveRed,
                  alignLeft: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Gols: ${h2h.teamAGoals} – ${h2h.teamBGoals}',
              style: AppTextStyles.caption,
            ),
          ),
        ],
      ),
    );
  }
}

class _H2HBar extends StatelessWidget {
  final String label;
  final double flex;
  final Color color;
  final bool alignLeft;
  const _H2HBar({required this.label, required this.flex, required this.color, required this.alignLeft});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Text(label, style: AppTextStyles.caption),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.full),
          child: LinearProgressIndicator(
            value: flex,
            backgroundColor: AppColors.cardBorder,
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

// ===========================================================================
// BET INPUT PANEL — stepper +/- premium
// ===========================================================================
class _BetInputPanel extends StatelessWidget {
  final int homeScore;
  final int awayScore;
  final String homeLabel;
  final String awayLabel;
  final bool submitted;
  final void Function(int) onHomeChange;
  final void Function(int) onAwayChange;
  final VoidCallback onSubmit;

  const _BetInputPanel({
    required this.homeScore,
    required this.awayScore,
    required this.homeLabel,
    required this.awayLabel,
    required this.submitted,
    required this.onHomeChange,
    required this.onAwayChange,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    if (submitted) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.neonGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.neonGreen.withOpacity(0.4)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_rounded, color: AppColors.neonGreen, size: 18),
              const SizedBox(width: 8),
              Text(
                'Palpite $homeScore – $awayScore enviado!',
                style: AppTextStyles.body.copyWith(color: AppColors.neonGreen, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.sports_soccer_rounded, color: AppColors.neonBlue, size: 15),
              const SizedBox(width: 6),
              Text('Fazer palpite', style: AppTextStyles.label.copyWith(color: AppColors.neonBlue)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ScoreStepper(
                  label: homeLabel,
                  value: homeScore,
                  onChanged: onHomeChange,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('×', style: AppTextStyles.h2.copyWith(color: AppColors.textMuted, fontSize: 18)),
              ),
              Expanded(
                child: _ScoreStepper(
                  label: awayLabel,
                  value: awayScore,
                  onChanged: onAwayChange,
                ),
              ),
              const SizedBox(width: 12),
              NeonButton(label: 'Palpitar', onTap: onSubmit, height: 48, width: 90),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScoreStepper extends StatelessWidget {
  final String label;
  final int value;
  final void Function(int) onChanged;
  const _ScoreStepper({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: AppTextStyles.caption.copyWith(fontSize: 9)),
        const SizedBox(height: 4),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.bgSecondary,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StepBtn(icon: Icons.remove_rounded, onTap: value > 0 ? () { HapticFeedback.selectionClick(); onChanged(value - 1); } : null),
              Text(
                '$value',
                style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
              _StepBtn(icon: Icons.add_rounded, onTap: value < 20 ? () { HapticFeedback.selectionClick(); onChanged(value + 1); } : null),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _StepBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 36, height: 48,
        child: Icon(icon, size: 18, color: onTap != null ? AppColors.neonBlue : AppColors.textMuted),
      ),
    );
  }
}

// ===========================================================================
// LIVE EVENTS PANEL
// ===========================================================================
class _LiveEventsPanel extends StatelessWidget {
  final List<LiveEvent> events;
  const _LiveEventsPanel({required this.events});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Eventos', style: AppTextStyles.label),
          const SizedBox(height: 8),
          ...events.map((e) => _EventRow(event: e)),
        ],
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  final LiveEvent event;
  const _EventRow({required this.event});

  IconData get _icon {
    switch (event.type) {
      case 'goal':        return Icons.sports_soccer_rounded;
      case 'yellow_card': return Icons.square_rounded;
      case 'red_card':    return Icons.square_rounded;
      default:            return Icons.swap_horiz_rounded;
    }
  }

  Color get _color {
    switch (event.type) {
      case 'goal':        return AppColors.neonGreen;
      case 'yellow_card': return AppColors.gold;
      case 'red_card':    return AppColors.liveRed;
      default:            return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: _color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(_icon, color: _color, size: 16),
          ),
          const SizedBox(width: 10),
          Text("${event.minute}'", style: AppTextStyles.caption.copyWith(color: _color, fontWeight: FontWeight.w700, fontSize: 12)),
          const SizedBox(width: 8),
          Expanded(child: Text(event.playerName, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary))),
        ],
      ),
    );
  }
}

// ===========================================================================
// EXPAND BUTTON
// ===========================================================================
class _ExpandButton extends StatelessWidget {
  final Animation<double> arrowAnim;
  final VoidCallback onTap;
  const _ExpandButton({required this.arrowAnim, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Center(
          child: RotationTransition(
            turns: arrowAnim,
            child: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textMuted, size: 22),
          ),
        ),
      ),
    );
  }
}
